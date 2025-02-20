{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.physical

    fail2ban
    graphical.dashboard
    vpn.wireguard-admin
  ];

  age.secrets."abuseipdb-api.key".file = ../secrets/abuseipdb-api-key.age;

  rnl.labels.location = "inf3-p2-admin";

  # Storage
  rnl.storage.disks.root = [ "/dev/disk/by-id/ata-WDC_WD5000AZRX-00A8LB0_WD-WCC1U3744017" ];

  # Networking
  networking = {
    interfaces.enp2s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.216";
          prefixLength = 27;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:82::216";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.222";
    defaultGateway6.address = "2001:690:2100:82::ffff:1";
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
  environment.systemPackages = with pkgs; [ x11vnc ];

  # ARPwatch (Admin)
  services.arpwatch = {
    enable = true;
    interfaces.enp2s0 = { };
  };

  # Dashboard
  systemd.services.dashboard-server =
    let
      dashboardPort = 7331; # Port to serve the dashboard (randomly chosen)
      dashboardDir = pkgs.writeTextDir "dashboard_admin.json" (
        lib.generators.toJSON { } {
          settingsReloadIntervalMinutes = 20;
          fullscreen = true;
          autoStart = true;

          websites = [
            {
              url = "https://rnl.tecnico.ulisboa.pt";
              duration = 5;
              tabReloadIntervalSeconds = 3600;
            }
            {
              url = "https://rnl.tecnico.ulisboa.pt/dashboard";
              duration = 5;
              tabReloadIntervalSeconds = 600;
            }
            {
              url = "https://grafana.rnl.tecnico.ulisboa.pt/d/D7PpwMQVk/labswatch?orgId=1&refresh=1m&theme=dark&kiosk";
              duration = 10;
              tabReloadIntervalSeconds = 3600;
            }
            {
              url = "https://grafana.rnl.tecnico.ulisboa.pt/d/f9baf51c-7055-427c-a9d2-19a6584efc47/grafana-alert?orgId=1&refresh=1m&theme=dark&kiosk";
              duration = 10;
              tabReloadIntervalSeconds = 3600;
            }
          ];
        }
      );
    in
    {
      description = "Dashboard HTTP Server";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.simple-http-server}/bin/simple-http-server --ip 127.0.0.1 --nocache -p ${toString dashboardPort} ${dashboardDir}";
        Restart = "always";
        User = "nobody";
      };
    };

  # WoL Bridge
  rnl.wolbridge = {
    enable = true;
    openFirewall = true;
    domain = config.rnl.domain;
    pingHosts = [ "193.136.164.{193..221}" ];
    configFile = pkgs.writeText "wolbridge-config.json" (
      lib.generators.toJSON { } {
        all = [
          "rnl"
          "dei"
        ];
        rnl = [
          "torvalds"
          "pikachu"
          "geoff"
          "thor"
          "raijin"
          "raidou"
        ];
        dei = [
          "prohmakas"
          "marte"
          "sazed"
          "peras"
        ];
      }
    );
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
