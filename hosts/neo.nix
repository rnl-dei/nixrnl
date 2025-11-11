{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6
    os.nixos
    type.hypervisor
    backups
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_22234X803001"
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_23204N400452"
      ];
      data = [
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_34N0A07VFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A04YFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A05SFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A065FVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A067FVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A06PFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A07MFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_54M0A08QFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_74D0A0GLFVGG"
        "/dev/disk/by-id/ata-TOSHIBA_MG08ACA16TE_74D0A0GNFVGG"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "975f3390"; # Randomly generated

    bonds.bond0 = {
      interfaces = [
        "enp33s0f0"
        "enp33s0f1"
      ];
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
      priv = {
        interfaces = [ "bond0" ];
      };
      pub = {
        interfaces = [ "pub-vlan" ];
      };
      labs = {
        interfaces = [ "labs-vlan" ];
      };
      dmz = {
        interfaces = [ "dmz-vlan" ];
      };
      gia = {
        interfaces = [ "gia-vlan" ];
      };
      portateis = {
        interfaces = [ "portateis-vlan" ];
      };
    };

    interfaces.priv = {
      ipv4.addresses = [
        {
          address = "193.136.164.108";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::108";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  users.users.root.hashedPassword = "$6$.fC8iZ1hbW6mXgSU$qbnyqGSuC2cGPqlxlKkqMHXKX9Mqg/VuMFHmfOeY1FNW2e3l4LGjsu9YdXkaX5tCTXkS5xOpSS8tGyUnhrRFO1";

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.priv.accept_ra" = 1;
  };
}
