{
  lib,
  config,
  pkgs,
  ...
}: let
  pamCreateGlusterHome =
    pkgs.writeShellScript "pam_create_gluster_home.sh"
    (builtins.readFile ./pam_create_gluster_home.sh);
in {
  imports = [../common.nix];

  services.slurm.server.enable = true;

  # Ensure slurmctld does not run without /mnt/cirrus being mounted
  systemd.services.slurmctld = {
    requires = ["mnt-cirrus.mount"];
    after = ["mnt-cirrus.mount"];
    partOf = ["mnt-cirrus.mount"];
  };

  # Slurmctld port and srun batch ports
  networking.firewall = {
    allowedTCPPorts = [6817];
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

      [1;31mSafeguard[0m your work by saving to AFS or your computer before logging out.

      Please [1;31mdo not perform computation on this machine.[0m Use the cluster instead.
      Processes consuming excessive ammounts of RAM/CPU on this machine will be
      terminated without warning.

    ################################################################################

  '';

  security.pam.services.login.text = lib.mkDefault (lib.mkAfter "session optional pam_exec.so seteuid ${pamCreateGlusterHome}");
  security.pam.services.sshd.text = lib.mkDefault (lib.mkAfter "session optional pam_exec.so seteuid ${pamCreateGlusterHome}");
}
