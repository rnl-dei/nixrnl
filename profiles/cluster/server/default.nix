{
  lib,
  config,
  pkgs,
  ...
}: let
  pamCreateGlusterHome =
    pkgs.writeShellScript "pam_create_gluster_home.sh"
    (builtins.readFile ./pam_create_gluster_home.sh);

  databaseName = "slurm_acct_db";
in {
  imports = [../common.nix];

  # Fix to allow slurmdbd with external database
  systemd.services.slurmdbd.requires = lib.mkForce ["munged.service"];

  services.slurm = {
    server.enable = true;
    dbdserver = {
      enable = true;
      extraConfig = ''
        StorageHost=${config.rnl.database.host}
        StoragePort=${toString config.rnl.database.port}
        StorageLoc=${databaseName}

        PrivateData=accounts,events,usage,users
      '';
    };
  };
  rnl.db-cluster = {
    ensureDatabases = [databaseName];
    ensureUsers = [
      {
        name = "slurm";
        ensurePermissions = {
          "${databaseName}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Ensure slurmctld does not run without /mnt/cirrus being mounted
  systemd.services.slurmctld = {
    requires = ["mnt-cirrus.mount"];
    after = ["mnt-cirrus.mount"];
    partOf = ["mnt-cirrus.mount"];
  };

  # Slurmctld port and srun batch ports
  networking.firewall = {
    allowedTCPPorts = [6817 6819];
    allowedTCPPortRanges = [
      {
        from = 60001;
        to = 63000;
      }
    ];
  };

  users.motd = ''

    ################################################################################

      [1;37mWelcome to RNL Cluster[0m - cluster@rnl.tecnico.ulisboa.pt
      https://rnl.tecnico.ulisboa.pt/servicos/cluster/

      Your [1;31mvolatile[0m workspace is located at:

          [1m/mnt/cirrus/users/[1;33mY[0;1m/[1;32mZ[0;1m/[1;34mistxxxx[1;33my[1;32mz[0m

          also available in the $CLUSTER_HOME environment variable

      Jobs launched with [1;34msrun[0m will have their $HOME set to $CLUSTER_HOME.

      [1;31mSafeguard[0m your work by saving to AFS or your computer before logging out.

      Please [1;31mdo not perform computation on this machine.[0m Use the cluster instead.
      Processes consuming excessive ammounts of RAM/CPU on this machine will be
      terminated without warning.

      ------------------------------------------------
      [1;31mIMPORTANT NOTICE:[0m
      Users' workspaces have been cleaned. If you need any files that were previously under
      your $CLUSTER_HOME, please send us an e-mail with your istid.
      [1;34mcluster@rnl.tecnico.ulisboa.pt[0m
      ------------------------------------------------

    ################################################################################

  '';

  security.pam.services.login.text = lib.mkDefault (lib.mkAfter "session optional pam_exec.so seteuid ${pamCreateGlusterHome}");
  security.pam.services.sshd.text = lib.mkDefault (lib.mkAfter "session optional pam_exec.so seteuid ${pamCreateGlusterHome}");

  # Limit individual user's memory usage aggressively
  # This is a heavily shared machine
  # Overrides limits from profile/ist-shell
  # TODO: move to somewhere where it can be shared with nexus and other heavily shared machines.
  systemd.slices."user-".sliceConfig = {
    MemoryMax = "13%"; # 2GB * 12% ≃ 260MB

    # Page cache management is dumb and reclamation is not automatic when memory runs out
    # MemoryHigh is a soft-limit that triggers aggressive memory reclamation, preventing OOM kills when the page cache starts to grow
    # This prevents something like downloading a large file to a FS with a large write cache from being OOM-killed
    MemoryHigh = "12%"; # set to just under MemoryMax

    # Prevent fork-bombs
    TasksMax = 384; # 4096 is too much in a low-spec machine
    # If the value is set too high, OOM killer will kick in first and leave the machine sluggish (not impossible to recover, but still annoying).
  };
}
