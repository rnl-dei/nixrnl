{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.hypervisor
    backups
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

    interfaces.pub = {
      ipv4.addresses = [
        {
          address = "193.136.164.5";
          prefixLength = 26;
        }
        {
          address = "193.136.164.4";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::5";
          prefixLength = 64;
        }
        {
          address = "2001:690:2100:80::4";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";
  };

  users.users.root.hashedPassword = "$6$q5qLU8WwsJfRTYGI$IlbfIYFhGS.Lozdd5Cund.7iKgGgdJzXMUCzitl4V.Q5VLR.Ow7sUsZda9hVwYpLHnFcVRGMG6V71omooyRI80";

  # NFS
  systemd.tmpfiles.rules = [ "d /mnt/data/cirrus/users 0775 nobody nogroup -" ];
  services.nfs.server = {
    enable = true;
    # allow borg and labs to mount cirrus
    exports = ''
      /mnt/data/cirrus 193.136.164.138(rw,async,no_subtree_check,no_root_squash)
      /mnt/data/cirrus 2001:690:2100:83::138(rw,async,no_subtree_check,no_root_squash)
      /mnt/data/cirrus 193.136.154.0/25(rw,async,no_subtree_check,no_root_squash)
      /mnt/data/cirrus 2001:690:2100:84::/64(rw,async,no_subtree_check,no_root_squash)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];
  boot.kernel.sysctl = {
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.pub.accept_ra" = 1;
  };

  #NTP
  services.ntp = {
    enable = true;
    servers = [
      "hora.rediris.es"
      "ntp1.software.imdea.org"
      "ntp04.oal.ul.pt"
      "servers ntp01.fccn.pt"
    ];
    extraConfig = ''
      interface listen 193.136.164.4
      interface listen 2001:690:2100:80::4
    '';
  };
  networking.firewall.allowedUDPPorts = [ 123 ];
}
