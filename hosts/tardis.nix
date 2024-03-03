{
  profiles,
  config,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.physical
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        # TODO: Add root disk (2 SSDs of >200 GB)
      ];
      data = [
        # TODO: Add data disks (2 HDD disks of 3TB each is enough)
      ];
    };
  };

  # Networking
  networking = {
    hostId = "0725d120"; # Randomly generated

    interfaces.eno1 = {
      ipv4 = {
        addresses = [
          {
            address = "193.136.164.82";
            prefixLength = 26;
          }
        ];
        routes = [
          {
            address = "0.0.0.0";
            prefixLength = 0;
            via = "193.136.164.126";
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2001:690:2100:81::82";
            prefixLength = 64;
          }
        ];
        routes = [
          {
            address = "::";
            prefixLength = 0;
            via = "2001:690:2100:81::ffff:1";
          }
        ];
      };
    };

    interfaces.mgmt = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.102.1";
            prefixLength = 22;
          }
        ];
        routes = [
          {
            address = "192.168.100.0";
            prefixLength = 22;
            via = "192.168.102.1";
          }
        ];
      };
    };
  };

  # VLANs
  networking.vlans = {
    mgmt = {
      id = config.rnl.vlans.mgmt;
      interface = "eno1";
    };
  };
}
