{
  lib,
  config,
  pkgs,
  ...
}: let
  slurmProlog = pkgs.writeShellScript "slurm-prolog.sh" ''
    #!/bin/sh
    set -e
    # Ensure subuid/subgid assignments exist for job user for container usage
    PAM_USER=$SLURM_JOB_USER ${pkgs.subidappend}/bin/subidappend

    # Make systemd create /run/user/<uid> (for container usage)
    ${pkgs.systemd}/bin/loginctl enable-linger $SLURM_JOB_USER
  '';
  slurmTaskProlog = pkgs.writeShellScript "slurm-taskprolog.sh" ''
    #!/bin/sh
    set -e
    # set DOCKER_HOST for container usage
    echo export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    echo export HOME=$CLUSTER_HOME
  '';
  slurmEpilog = pkgs.writeShellScript "slurm-epilog.sh" ''
    #!/bin/sh
    set -e
    # systemd can now clear up /run/user/<uid> and other resources
    # TODO: fix race condition with other jobs from same user in same node
    ${pkgs.systemd}/bin/loginctl disable-linger $SLURM_JOB_USER
  '';
in {
  services.slurm = {
    controlMachine = lib.mkDefault "borg";
    clusterName = lib.mkDefault "RNL-Cluster";
    dbdserver.dbdHost = lib.mkDefault "borg";
    nodeName = lib.mkDefault [
      "lab0p[1-6] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab0"
      "lab1p[1-12] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab1"
      "lab2p[1-20] Sockets=1 CoresPerSocket=6 ThreadsPerCore=1 RealMemory=10240 Features=lab2"
      "lab3p[1-10] Sockets=1 CoresPerSocket=6 ThreadsPerCore=1 RealMemory=10240 Features=lab3"
      "lab4p[1-10] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab4"
      "lab5p[1-20] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab5"
      "lab6p[1-9] Sockets=1 CoresPerSocket=6 ThreadsPerCore=1 RealMemory=10240 Features=lab6"
      "lab7p[1-9] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab7"
    ];
    partitionName = lib.mkDefault [
      "compute Nodes=lab0p[1-6],lab1p[1-12],lab2p[1-20],lab3p[1-10],lab4p[1-10],lab5p[1-20],lab6p[1-9],lab7p[1-9] Default=YES MaxTime=20160 DefaultTime=30 State=UP"
    ];
    procTrackType = "proctrack/cgroup";
    extraConfig = ''
      SrunPortRange=60001-63000 # Don't forget to enable these ports in your firewall on slurm server

      # TODO: nodes are currently re-added to the cluster automatically, regardless of the reason that caused them to be kicked out.
      # set ReturnToService=1 to avoid this. However, this requires rebooting nodes using slurm, always.
      # So the system must use this facility to reboot: requires internal tooling to make `reboot` use slurm internally, changing DE behavior (dunno how).
      ReturnToService=2
      TaskPlugin=task/cgroup,task/affinity
      TreeWidth=10 # Square root of the number of nodes
      SelectType=select/cons_tres
      SelectTypeParameters=CR_CPU_Memory
      JobAcctGatherType=jobacct_gather/cgroup
      PrologFlags=Contain
      DefMemPerCPU=1024
      DefMemPerGPU=1024
      GresTypes=gpu,mps

      MpiDefault=pmix

      AccountingStorageType=accounting_storage/slurmdbd
      AccountingStorageHost=${config.services.slurm.dbdserver.dbdHost}
      AccountingStoreFlags=job_comment

      Prolog=${slurmProlog}
      TaskProlog=${slurmTaskProlog}
      Epilog=${slurmEpilog}
    '';
    extraCgroupConfig = ''
      ConstrainCores=yes
      ConstrainDevices=yes
      ConstrainRAMSpace=yes
      ConstrainSwapSpace=yes
    '';
  };

  # TODO: May be necessary to change kernel for cgroups swap support
  # If so, set the MEMCG_SWAP kernel parameter to 1 and change the kernel
  # Example:
  # ```
  # boot.kernelPackages = let
  #   linuxRNL = prev.linuxPackagesFor (prev.linux_xanmod.override {
  #     structuredExtraConfig = with prev.lib.kernel; { MEMCG_SWAP = yes; };
  #     ignoreConfigErrors = true;
  #   })
  # in linuxRNL;
  # ```

  age.secrets."munge.key" = {
    file = ../../secrets/munge-key.age;
    mode = "0400";
    owner = "munge";
    path = "/etc/munge/munge.key";
    symlink = false; # Munge requires the key to be a regular file
  };

  # Setup cirrus
  environment.systemPackages = [pkgs.glusterfs pkgs.mpi];

  fileSystems."/mnt/cirrus" = {
    device = lib.mkDefault "dredd:/mnt/data/cirrus";
    fsType = "nfs";
    options = ["noauto" "x-systemd.automount" "nfsvers=4.2"];
  };

  environment.shellInit = ''
    # This is sourced by the shell (not executed), so we're extra careful to avoid bashisms

    if echo "$USER" | grep -E "^ist[0-9]+$" 2>&1 >/dev/null; then
      # Format: /mnt/cirrus/users/Y/Z/istxxxxxYZ
      Y="$(echo "$USER" | rev | cut -c 2)"
      Z="$(echo "$USER" | rev | cut -c 1)"
      export CLUSTER_HOME="/mnt/cirrus/users/$Y/$Z/$USER"
    else
      # fallback
      export CLUSTER_HOME="$HOME"
    fi
  '';

  # Get authorized keys from cirrus.
  # Cluster users rarely need AFS to work.
  # TODO: this is somewhat destructive, as only one authorizedKeysCommand can be specified.
  # Consider building some sort of configurable authorizedKeysCommand and using it everywhere instead.
  services.openssh.authorizedKeysCommand = "/etc/ssh/cat-cirrus-authorized-keys.sh %u";

  environment.etc."ssh/cat-cirrus-authorized-keys.sh" = {
    mode = "0555";
    source = pkgs.writeShellScript "cat-cirrus-authorized-keys.sh" ''
      #!${pkgs.bash}/bin/bash
      # Outputs authorized_keys for a user from their cirrus (GlusterFS) home
      # Arguments: <username>

      # This script is meant to be run as root by OpenSSH using the AuthorizedKeyCommand option
      # It will be run **after** the usual authorized_keys files are checked,
      # and its output (stdout) is interpreted as the contents of yet another authorized_keys file

      # WARNING: THE USER WAS NOT AUTHENTICATED AT ALL YET, THAT'S THE WHOLE POINT
      # ...so careful with what you do here

      if [ "$#" -ne 1 ]; then
          echo "Usage: $0 <username>" 1>&2
          exit 1
      fi

      # users can login using "name.lastname" or something instead of istxxxxx
      USER="$(${pkgs.coreutils}/bin/id -u --name "$1")" || exit 1

      check_file_perms() {
          local file="$1"

          [ -f "$file" ] \
                  && [ "$(${pkgs.coreutils}/bin/stat -c '%U' "$1")" = "$USER" ] \
                  && [ "$(${pkgs.coreutils}/bin/stat -c '%a' "$1")" = "600" ]
      }

      if [[ "$USER" =~ ^ist[0-9]+$ ]]; then
          # Format: /mnt/cirrus/users/Y/Z/istxxxxyz
          Y=''${USER:(-2):1}
          Z=''${USER:(-1):1}
          GLUSTER_HOME="/mnt/cirrus/users/$Y/$Z/$USER"

          for file in $GLUSTER_HOME/.ssh/authorized_keys{,2}; do
                  if check_file_perms "$file"; then
                          ${pkgs.coreutils}/bin/cat "$file"
                  fi
          done
      fi
    '';
  };

  services.openssh.authorizedKeysCommandUser = "root";

  # Likewise, have the openssh *client* use keys stored in cirrus
  programs.ssh.extraConfig = ''
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_rsa
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_ecdsa
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_ecdsa_sk
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_ed25519
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_ed25519_sk
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_xmss
    IdentityFile ''${CLUSTER_HOME}/.ssh/id_dsa
  '';
}
