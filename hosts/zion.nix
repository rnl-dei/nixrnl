{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6
    os.nixos
    type.hypervisor
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-ADATA_SU900_2J1020057939"
        "/dev/disk/by-id/ata-ADATA_SU900_2J1020053177"
      ];
      data = [
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17M1KGZVF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17M7KK9PF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17M9KEZAF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17MQK05LF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17N1KH0HF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA400_17N1KH0IF"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "a3df128e"; # Randomly generated

    bonds.bond0 = {
      interfaces = ["enp6s0" "enp7s0"];
      driverOptions.mode = "802.3ad";
    };

    vlans = {
      pub-vlan = {
        id = config.rnl.vlans.pub;
        interface = "bond0";
      };
      labs-vlan = {
        id = config.rnl.vlans.labs;
        interface = "bond0";
      };
      dmz-vlan = {
        id = config.rnl.vlans.dmz;
        interface = "bond0";
      };
      gia-vlan = {
        id = config.rnl.vlans.gia;
        interface = "bond0";
      };
      portateis-vlan = {
        id = config.rnl.vlans.portateis;
        interface = "bond0";
      };
    };

    bridges = {
      priv = {interfaces = ["bond0"];};
      pub = {interfaces = ["pub-vlan"];};
      labs = {interfaces = ["labs-vlan"];};
      dmz = {interfaces = ["dmz-vlan"];};
      gia = {interfaces = ["gia-vlan"];};
      portateis = {interfaces = ["portateis-vlan"];};
    };

    interfaces.priv = {
      ipv4 = {
        addresses = [
          {
            address = "193.136.164.69";
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
            address = "2001:690:2100:81::69";
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
  };

  users.users.root.hashedPassword = "$6$zhD1fBAElFJswbcs$d4Ib0y33S2cywpgHXKj9Pd3TOn9R5a0pSmannqVXzjaG10hipMgvhKcapRXBMLvYrgLZUAh9vLBw3co61vdV2/";

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.priv.accept_ra" = 1;
  };
}
