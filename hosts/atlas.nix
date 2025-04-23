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
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_241332800312"
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_241332800356"
      ];
      data = [
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X631KI0SF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X631KI0VF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X631KI0XF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64BK4I2F"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64BK4I4F"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64DK05GF"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64FKDG4F"
        "/dev/disk/by-id/ata-TOSHIBA_MG03ACA300_X64GK029F"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5RPRL"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5T10L"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "b5747d70"; # Randomly generated

    bonds.bond0 = {
      interfaces = [
        "enp33s0f2"
        "enp33s0f3"
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
          address = "193.136.164.72";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::72";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  users.users.root.hashedPassword = "$y$j9T$34DLz.tknuyTFl0bgSV7N0$VF5JsaBM6Q6gWgtcoRt9saSP9pTUGsNK0h5WthD9n38";

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.priv.accept_ra" = 1;
  };
}
