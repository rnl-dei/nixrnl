{
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.83";
          prefixLength = 26;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
  };

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "DB arbitrator";
    createdBy = "nuno.alves";

    interfaces = [{source = "priv";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/db0";}];
  };

  # Galera Arbitrator
  # https://github.com/codership/galera/blob/644e7f04139079566a03109ce105d658a043d0a9/garb/files/garb.service
  systemd.services.garbd = let
    arbitratorConfigFile = pkgs.writeText "garbd.cnf" ''
      name = db0
      group = rnl_db_cluster
      address = gcomm://db2,db1,db0
    '';
  in {
    description = "Galera Arbitrator Daemon";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    unitConfig = {
      Documentation = ["man:garbd(8)" "https://galeracluster.com/library/documentation/arbitrator.html"];
    };
    serviceConfig = {
      User = "nobody";
      ExecStart = "${pkgs.mariadb-galera}/bin/garbd --cfg ${arbitratorConfigFile}";

      # Use SIGINT because with the default SIGTERM
      # garbd fails to reliably transition to 'destroyed' state
      KillSignal = "SIGINT";

      TimeoutSec = "2m";
      PrivateTmp = false;
    };
  };

  networking.firewall = let
    garbdPort = 4567;
  in {
    allowedTCPPorts = [garbdPort];
    allowedUDPPorts = [garbdPort];
  };

  users.motd = ''

    ################################################################################

      [1;31mRNL DB cluster [0m[2m--> https://weaver.rnl.tecnico.ulisboa.pt/dokuwiki/doku.php?id=servicos:db_cluster[0m

      * [0;31mList of configured nodes:[0m
          - [1;34mdb0[0m (arbitrator)
          - [1;34mdb1[0m
          - [1;34mdb2[0m

      * [0;31mThis is just an arbitrator node.[0m  [0m[2m--> https://galeracluster.com/library/documentation/arbitrator.html [0m

    ################################################################################

  '';
}
