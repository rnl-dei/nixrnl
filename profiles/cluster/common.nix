{
  lib,
  config,
  pkgs,
  ...
}: {
  services.slurm = {
    controlMachine = "borg";
    clusterName = lib.mkDefault "RNL-Cluster";
    nodeName = lib.mkDefault [
      "lab1p[1-12] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab1"
      "lab2p[1-20] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab2"
      "lab3p[1-10] Sockets=1 CoresPerSocket=6 ThreadsPerCore=2 RealMemory=10240 Features=lab3"
      "lab4p[1-10] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab4"
      "lab5p[1-20] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab5"
      "lab6p[1-9] Sockets=1 CoresPerSocket=6 ThreadsPerCore=1 RealMemory=10240 Features=lab6"
      "lab7p[1-9] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab7"
    ];
    partitionName = lib.mkDefault [
      "compute Nodes=lab1p[1-12],lab2p[1-20],lab3p[1-10],lab4p[1-10],lab5p[1-20],lab6p[1-9],lab7p[1-9] Default=YES MaxTime=20160 DefaultTime=30 State=UP"
    ];
    procTrackType = "proctrack/cgroup";
    extraConfig = ''
      SrunPortRange=60001-63000 # Don't forget to enable these ports in your firewall on slurm server

      ReturnToService=1
      TaskPlugin=task/cgroup,task/affinity
      TreeWidth=10 # Square root of the number of nodes
      SelectType=select/cons_tres
      SelectTypeParameters=CR_CPU_Memory
      JobAcctGatherType=jobacct_gather/cgroup
      PrologFlags=Contain
      DefMemPerCPU=1024
      DefMemPerGPU=1024
    '';
    extraCgroupConfig = ''
      ConstrainCores=yes
      ConstrainDevices=yes
      ConstrainRAMSpace=yes
      ConstrainSwapSpace=yes
    '';
  };

  # TODO: May be necessary to change kernel

  age.secrets."munge.key" = {
    file = ../../secrets/munge-key.age;
    mode = "0400";
    owner = "munge";
    path = "/etc/munge/munge.key";
    symlink = false; # Munge requires the key to be a regular file
  };

  # Setup cirrus
  environment.systemPackages = [pkgs.glusterfs];
  fileSystems."/mnt/cirrus" = {
    device = lib.mkDefault "luz:/cirrus";
    fsType = "glusterfs";
    options = ["defaults" "backup-volfile-servers=lampada:meninx" "acl"];
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
}
