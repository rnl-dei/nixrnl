{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.hypervisor
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_23204N400004"
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_23204N400482"
      ];
      data = [
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64BK4I1F"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64GK028F"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "53ad07f3"; # Randomly generated

    bonds.bond0 = {
      interfaces = ["eno1" "eno2"];
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
            address = "193.136.164.66";
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
            address = "2001:690:2100:81::66";
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

  users.users.root.hashedPassword = "$6$q5qLU8WwsJfRTYGI$IlbfIYFhGS.Lozdd5Cund.7iKgGgdJzXMUCzitl4V.Q5VLR.Ow7sUsZda9hVwYpLHnFcVRGMG6V71omooyRI80";
}
