{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.physical

    pixiecore
    opentracker
    transmission.labs
  ];

  rnl.labels.location = "inf1-p01-a3";

  # Storage
  rnl.storage.disks.root = [
    "/dev/disk/by-id/ata-WDC_WD1002F9YZ-09H1JL1_WD-WMC5K0D3AW7K"
  ];

  # Networking
  networking.interfaces.eno1 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.154.125";
          prefixLength = 25;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.154.126";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:84:8000::125";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "fe80::96f7:ad00:28af:fa13";
        }
      ];
    };
  };

  users.users.root.hashedPassword = "$6$fBxN95kuNpq4Nxhq$Rev.mpIltLW7keZoT/LLtuamiggGTpBtfs.Z.8ztxin9TI9ZksIUNYeOvc4RgQF.n.nlGAlXRI4IBxyFj3VSa/";

  environment.shellAliases = {
    create-torrent = "transmission-create -p -t udp://tracker.${config.rnl.domain}:31000";
  };
}
