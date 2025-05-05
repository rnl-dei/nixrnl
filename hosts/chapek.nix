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
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_22234X802979"
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_22234X803010"
      ];
      data = [
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E4MKRK"
        "/dev/disk/by-id/ata-TOSHIBA_DT01ACA300_Z2P5D71AS"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E2ZN2Y"
        "/dev/disk/by-id/ata-TOSHIBA_DT01ACA300_Z2P5M5XAS"
        "/dev/disk/by-id/ata-TOSHIBA_DT01ACA300_Z2P5JJPAS"
        "/dev/disk/by-id/ata-ST3000VN000-1HJ166_W6A0J5JN"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "d5cc31cd"; # Randomly generated

    bonds.bond0 = {
      interfaces = [
        "eno1"
        "eno2"
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
          address = "193.136.164.71";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::71";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  users.users.root.hashedPassword = "$6$fX4/nBpHDkTqbWwZ$hK.fbN258SPLJVVGjySbjUYbnMQRq9ddmBX57wqlR0tQnltVrBKfijmVRhBdDykaniVG7TYFiE63xId.m1Tko1";

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.priv.accept_ra" = 1;
  };
}
