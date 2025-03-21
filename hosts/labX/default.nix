{ profiles, pkgs, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab

    labs
    cluster.client
    cluster.tests
  ];

  rnl.storage.disks.root = [ "/dev/sda" ];

  rnl.labels.location = "inf1-p01-estaleiro";

  users.users.exo = {
    isNormalUser = true;
    description = "Simple user to run exo";
  };

  systemd.services.exo = {
    description = "exo";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      CPU = "1";
      # # EXO_HOME = "$CLUSTER_HOME";
    };
    serviceConfig = {
      User = "exo";
      Type = "simple";
      ExecStart = "/bin/sh -lc '${pkgs.exo}/bin/exo'";
      Restart = "always";
    };
  };
}
