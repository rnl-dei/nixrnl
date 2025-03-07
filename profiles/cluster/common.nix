{
  lib,
  config,
  pkgs,
  ...
}:
let
  slurmProlog = pkgs.writeShellScript "slurm-prolog.sh" ''
    #!/bin/sh
    set -e
    # send stdout/stderr to journal
    exec > >(${pkgs.systemd}/bin/systemd-cat -t "slurm-prolog.sh/$SLURM_JOB_USER") 2>&1

    # Ensure subuid/subgid assignments exist for job user for container usage
    PAM_USER=$SLURM_JOB_USER ${pkgs.subidappend}/bin/subidappend

    COUNTER_PATH=/run/slurm-count-"$SLURM_JOB_USER"
    (
      ${pkgs.util-linux}/bin/flock -e 200

      if [ ! -f "$COUNTER_PATH" ] || [[ "$(${pkgs.coreutils}/bin/cat "$COUNTER_PATH")" == "0" ]]; then
        # Make systemd create /run/user/<uid> (for container usage)
        ${pkgs.systemd}/bin/loginctl enable-linger "$SLURM_JOB_USER"

        echo 1 > "$COUNTER_PATH"
      else
        # count number of concurrent jobs from the same user to avoid calling
        # disable-linger prematurely in Slurm's Epilog
        prev_count="$(${pkgs.coreutils}/bin/cat "$COUNTER_PATH")"
        echo $(( prev_count + 1 )) > "$COUNTER_PATH"
      fi
    ) 200>"$COUNTER_PATH.lock"
  '';
  slurmTaskProlog = pkgs.writeShellScript "slurm-taskprolog.sh" ''
    #!/bin/sh
    set -e
    # send stderr to journal
    # don't send stdout: Slurm needs it to set env vars!
    exec 2> >(${pkgs.systemd}/bin/systemd-cat -t "slurm-task-prolog.sh/$SLURM_JOB_USER")

    # set DOCKER_HOST for container usage
    echo export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    echo export HOME=$CLUSTER_HOME
  '';
  slurmEpilog = pkgs.writeShellScript "slurm-epilog.sh" ''
    #!/bin/sh
    set -e
    # send stdout/stderr to journal
    exec > >(${pkgs.systemd}/bin/systemd-cat -t "slurm-epilog.sh/$SLURM_JOB_USER") 2>&1

    COUNTER_PATH=/run/slurm-count-"$SLURM_JOB_USER"
    (
      ${pkgs.util-linux}/bin/flock -e 200

      count="$(${pkgs.coreutils}/bin/cat "$COUNTER_PATH")"
      count="$(( count - 1 ))"

      # only call disable-linger when all jobs from the user have completed
      if [[ $count -le 0 ]]; then
        echo 0 > "$COUNTER_PATH"

        # systemd can now clear up /run/user/<uid> and other resources
        ${pkgs.systemd}/bin/loginctl disable-linger "$SLURM_JOB_USER"
      else
        echo "$count" > "$COUNTER_PATH"
      fi
    ) 200>"$COUNTER_PATH.lock"
  '';
in
{
  services.slurm = {
    controlMachine = lib.mkDefault "borg";
    clusterName = lib.mkDefault "RNL-Cluster";
    dbdserver.dbdHost = lib.mkDefault "borg";
    nodeName = lib.mkDefault [
      "lab0p[1-9] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=15360 Features=lab0,i5-7500"
      "lab1p[1-12] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=15360 Features=lab1,i5-7500"
      "lab2p[1-20] Sockets=1 CoresPerSocket=6 ThreadsPerCore=2 RealMemory=15360 Features=lab2,i5-11500"
      "lab3p[1-10] Sockets=1 CoresPerSocket=6 ThreadsPerCore=2 RealMemory=15360 Features=lab3,i5-10500,rtx3060ti"
      "lab4p[1-10] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=15360 Features=lab4,i5-7500"
      "lab5p[1-20] Sockets=1 CoresPerSocket=4 ThreadsPerCore=2 RealMemory=15360 Features=lab5,i5-12500T"
      "lab6p[1-9] Sockets=1 CoresPerSocket=6 ThreadsPerCore=1 RealMemory=15360 Features=lab6,i5-8500"
    ];
    partitionName = lib.mkDefault [
      "compute Nodes=lab0p[1-9],lab1p[1-12],lab2p[1-20],lab3p[1-10],lab4p[1-10],lab5p[1-20],lab6p[1-9] Default=YES MaxTime=20160 DefaultTime=30 State=UP"
    ];
    procTrackType = "proctrack/cgroup";
    extraConfig = ''
      SrunPortRange=60001-63000 # Don't forget to enable these ports in your firewall on slurm server

      # TODO: nodes are currently re-added to the cluster automatically, regardless of the reason that caused them to be kicked out.
      # set ReturnToService=1 to avoid this. However, this requires rebooting nodes using slurm, always.
      # So the system must use this facility to reboot: requires internal tooling to make `reboot` use slurm internally, changing DE behavior (dunno how).
      ReturnToService=2

      # slurmd sometimes takes longer than expected to kill jobs, causing nodes to drain.
      # According to internet people this is due to a mismatch between the default timeout
      # used in task/cgroup (120s) and the default UnkillableStepTimeout (60s).
      # reference: https://support.schedmd.com/show_bug.cgi?id=3941#c7
      # Note: UnkillableStepTimeout MUST be at least 5x MessageTimeout (10s by default).
      UnkillableStepTimeout=128

      TaskPlugin=task/cgroup,task/affinity
      TreeWidth=120 # Each slurmd daemon can communicate with up to 120 other slurmd daemons
      SelectType=select/cons_tres
      SelectTypeParameters=CR_CPU_Memory
      JobAcctGatherType=jobacct_gather/cgroup
      PrologFlags=Contain
      DefMemPerCPU=1024
      GresTypes=gpu,mps

      MpiDefault=pmix

      PriorityType=priority/multifactor
      PriorityWeightFairshare=1
      PriorityWeightAge=1
      PriorityFavorSmall=YES
      PriorityWeightJobsize=1

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
  environment.systemPackages = [
    pkgs.glusterfs
    pkgs.mpi
    pkgs.mpi.dev
  ];

  fileSystems."/mnt/cirrus" = {
    device = lib.mkDefault "dredd:/mnt/data/cirrus";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "nfsvers=4.2"
    ];
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
