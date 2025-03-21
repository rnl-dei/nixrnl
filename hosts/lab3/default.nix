{
  profiles,
  pkgs,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab

    labs
    cluster.client
    nvidia
  ];

  rnl.storage.disks.root = [ "/dev/nvme0n1" ];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab3";

  rnl.monitoring.amt = true;

  users.users.exo = {
    isNormalUser = true;
    description = "Simple user to run exo";
  };

  systemd.services.exo = {
    description = "exo";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
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
