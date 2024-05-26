{
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.physical

    fail2ban
    graphical.dashboard
    vpn.wireguard-admin
  ];

  rnl.labels.location = "inf3-p2-admin";

  # Storage
  rnl.storage.disks.root = [
    "/dev/disk/by-id/ata-WDC_WD5000AZRX-00A8LB0_WD-WCC1U3744017"
  ];

  # Networking
  networking.interfaces.enp2s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.216";
          prefixLength = 27;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.222";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:82::216";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:82::ffff:1";
        }
      ];
    };
  };

  users.users.root.hashedPassword = "$6$4llYIsPcdW8Og7ca$E2FWDD9ToDLPuP.GdUGrO4k5J3UFjsBK2fQbfl.KFdbAzB9hyFWUG0U3ZLnd0KxrWf0tZkzNvF2PG9r/QE.oY0";

  # Set this because of wireguard
  networking.nat.externalInterface = "enp2s0";

  # Set as master
  services.keepalived.vrrpInstances = {
    wireguardAdminIP4.priority = 255;
    wireguardAdminIP6.priority = 255;
  };

  # Allow VNC connections
  environment.systemPackages = with pkgs; [
    x11vnc
  ];

  # ARPwatch (Admin)
  services.arpwatch = {
    enable = true;
    interfaces.enp2s0 = {};
  };

  # Setup spotifyd to play music on TV
  # FIXME: This is not working due to a bug in spotifyd
  #        that do not allow more than one IPv4 on the same interface
  # services.spotifyd = {
  #   enable = true;
  #   settings = {
  #     global = {
  #       bitrate = 320;
  #       initial_volume = "50";
  #       volume_normalization = true;
  #       device_type = "t_v";
  #     };
  #   };
  # };
}
