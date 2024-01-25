{
  config,
  lib,
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6-full
    os.nixos
    type.physical

    webserver

    # Mirrors
    mirrors.archlinux
    mirrors.cygwin
    mirrors.debian.archive
    mirrors.debian.cd
    mirrors.debian.security
    mirrors.gentoo.distfiles
    mirrors.gentoo.portage
    mirrors.linuxmint.isos
    mirrors.linuxmint.packages
    mirrors.mxlinux.isos
    mirrors.mxlinux.packages
    mirrors.openbsd
    mirrors.opensuse
    mirrors.qubesos
    mirrors.slackware
    mirrors.ubuntu.archive
    mirrors.ubuntu.releases
    mirrors.videolan
    mirrors.zorinos
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E0FTMA"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E1F5M9"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E2WFW8"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E4LHFV"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E5C2UF"
        "/dev/disk/by-id/ata-WDC_WD3000FYYZ-01UL1B2_WD-WMC1F0E6649N"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5JT4L"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5TSJL"

        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5TSDL"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5SE5L"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H3HKZL"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5PJWL"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5MAKL"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5J9UL"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V8KAPRHR"
        # "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9GTY2NL"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "dc41255c";

    bonds.bond0 = {
      #interfaces = ["eno1" "eno2"];
      interfaces = ["enp2s0f0" "enp2s0f1"];
      driverOptions.mode = "802.3ad";
    };

    interfaces.bond0 = {
      ipv4 = {
        addresses = [
          {
            #address = "193.136.164.6"; # FTP
            address = "193.136.164.113"; # FTP
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
            address = "2001:690:2100:81::113";
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

  users.users.root.hashedPassword = "$6$kfeh.NIncaHBjal.$hBW1BCxftekx0bcwCkt3Hps2MFvMdSCk2rfTQ3Nj3nO4Xj2D7.EqwVWk9UgYqS/iGWak6d0HumgaUkQZKaNoQ1";

  environment.systemPackages = with pkgs; [archvsync];

  # Enable FTP server with imported mirrors profiles
  rnl.ftp-server.enable = true;

  services.nginx.virtualHosts.ftp = {
    default = true;
    serverName = lib.mkDefault "${config.networking.fqdn}";
    # FIXME: Configure firewall to enable ACME
    #enableACME = true;
    #addSSL = true;
    extraConfig = ''
      autoindex on;
      autoindex_exact_size off;
    '';
    locations = {
      "~ ^/pub" = { alias = config.rnl.ftp-server.rootDirectory; };
      "~ ^/debian" = { alias = "/mnt/data/ftp/pub/debian/"; }; # Recommended by Debian

      "~ ^/dei" = { alias = "/mnt/data/ftp/dei"; };
      # TODO: We probably want to add /dei-share with password protection
      "~ ^/labs" = {
        alias = "/mnt/data/ftp/labs";
        extraConfig = ''
          autoindex off;
          location ~ ^/labs/(windows|software) {
            autoindex on;
            allow 193.136.164.192/27; # admin v4
            allow 2001:690:2100:82::/64; # admin v6
            allow 193.136.154.0/25; # labs v4
            allow 193.136.154.128/26;# labs2 v4
            allow 2001:690:2100:84::/64; # labs v6
            deny all;
          }
        '';
      };

      # Public but not listed, to share temporary files
      "~ ^/tmp" = { alias = "/mnt/data/ftp/tmp"; extraConfig = "autoindex off;"; };
      "~ ^/priv" = {
        alias = "/mnt/data/ftp/priv";
        extraConfig = ''
          # Allow access only from the RNL networks
          allow 193.136.164.0/24;
          allow 193.136.154.0/24;
          allow 10.16.80.0/24;
          allow 2001:690:2100:80::/58;
          deny all;
        '';
      };
    };
  };

}
