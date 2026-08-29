{
  pkgs,
  lib,
  config,
  profiles,
  ...
}:
let
  motd = ''
          _____  _   _ _
         |  __ \| \ | | |
         | |__) |  \| | |
         |  _  /| . ` | |
         | | \ \| |\  | |___
         |_|  \_\_| \_|_____|

         RNL FTP/Rsync Server

      ftp.rnl.tecnico.ulisboa.pt

      IP Address: 193.136.164.6
      IPv6 Address: 2001:690:2100:80::6


     Rede das Novas Licenciaturas
           Tecnico Lisboa
          Lisboa - Portugal

    Email: rnl@rnl.tecnico.ulisboa.pt
  '';
in
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6
    os.nixos
    type.physical

    webserver

    # WARNING: Before enabling check the mirror for notes

    # TO consider
    # fedora
    # void
    # alpine
    # tails
    # freebsd
    # other foss software?

    # No mirror files for
    # sabayon (probably stop now that gentoo has bins?)
    # UBCD

    mirrors.archlinux # 130 GB
    mirrors.debian.archive # 1.44tb
    #mirrors.debian.cd # huge, maybe filter source?
    mirrors.debian.security # 155GB
    mirrors.cygwin # 115 gb
    mirrors.gentoo.distfiles # 800GB +
    mirrors.gentoo.portage # <1Gb
    mirrors.linuxmint.isos # 200 GB
    mirrors.linuxmint.packages # 50GB
    mirrors.mxlinux.isos # 47 GB
    mirrors.mxlinux.packages # 200 GB
    mirrors.openbsd # 1.36 Tb
    mirrors.opensuse # 6.79 Tb
    mirrors.qubesos # 1 TB
    mirrors.ubuntu.archive # 3.23 Tb
    mirrors.ubuntu.releases # 45 GB
    # mirrors.videolan 100GB?
    # mirrors.zorinos 183 GB and fill https://zorin.com/os/mirrors/
  ];

  rnl.labels.location = "inf1-p01-a2";
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-HP_SSD_S700_500GB_HBSA31040200923"
        "/dev/disk/by-id/ata-ADATA_SU900_2I2720065871"

      ];
      data = [
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V8KAPRHR"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9GTY2NL"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H3HKZL"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5PJWL"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5SE5L"
        "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5TSDL"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "dc41255c";

    bonds.bond0 = {
      interfaces = [
        "eno1"
        "eno2"
      ];
      driverOptions.mode = "802.3ad";
    };

    interfaces.bond0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.6"; # FTP
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::6";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";
  };

  environment.systemPackages = [ pkgs.archvsync ];

  users.users.root.hashedPassword = "$y$j9T$dWaZ5JBxtn1SQ1KMA2Su2.$naxrds5bf8uYgh24uKiBPoSrOGAtgoiaBLsNasEjje5";

  users.motd = motd;
  environment.etc."motd" = {
    text = motd;
    mode = "0444";
  };

  rnl.ftp-server = {
    enable = true;
    motd = builtins.toFile "motd" motd;
  };

  # HACK: seems to need to clone the repo once for bootstrap?
  rnl.githook = {
    enable = true;
    hooks.ftp-site = {
      url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/ftp-site.git";
      directoryMode = "755";
    };
  };

  systemd.services."remake-ftp-site" = {
    description = "Remake FTP homepage";
    startAt = "*-*-* 02:14:00";
    path = [
      pkgs.bash
      pkgs.gnum4
      pkgs.gnumake
      pkgs.gawk
      (pkgs.python3.withPackages (ps: [
        ps.jinja2
        ps.pyyaml
      ]))
    ];
    script = ''
      #!/usr/bin/env bash
      cd ${config.rnl.githook.hooks.ftp-site.path}
      make
    '';
  };

  age.secrets."root-at-ftp-ssh.key" = {
    file = ../secrets/root-at-ftp-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  systemd.tmpfiles.rules = [
    "d /root/.ssh 0750 root root"

    "d /mnt/data/ftp/pub 0775 mirror mirror"

    #HACK: Distro with subdirs for various mirrors dont create properly with tmpfiles.d
    "d /mnt/data/ftp/pub/debian 0775 mirror mirror"
    "d /mnt/data/ftp/pub/gentoo 0775 mirror mirror"
    "d /mnt/data/ftp/pub/ubuntu 0775 mirror mirror"

    # "d /mnt/data/ftp/pub/ubuntu/releases 0770 mirror mirror"

    "d /mnt/data/ftp/tmp 0755 root root"

    "d /mnt/data/ftp/dei 0750 root root"
    "d /mnt/data/ftp/dei-share 0750 root root"
    "d /mnt/data/ftp/priv 0750 root root"
  ];

  services.nginx.virtualHosts.ftp = {
    default = true;
    serverName = lib.mkDefault "${config.networking.fqdn}";
    root = config.rnl.githook.hooks.ftp-site.path + "/htdocs";
    enableACME = true;
    addSSL = true;
    extraConfig = ''
      autoindex on;
      autoindex_exact_size off;

      if_modified_since exact;
    '';

    locations = {
      "~ ^/pub" = {
        alias = config.rnl.ftp-server.rootDirectory + "/";
      };
      "~ ^/debian" = {
        alias = "/mnt/data/ftp/pub/debian/";
      }; # Recommended by Debian

      "~ ^/dei" = {
        alias = "/mnt/data/ftp/dei/";
      };
      # # TODO: We probably want to add /dei-share with password protection
      # TODO: test later
      # "~ ^/labs" = {
      #   alias = "/mnt/data/ftp/labs/";
      #   extraConfig = ''
      #     autoindex off;
      #     location ~ ^/labs/(windows|software) {
      #       autoindex on;
      #       allow 193.136.164.192/27; # admin v4
      #       allow 2001:690:2100:82::/64; # admin v6
      #       allow 193.136.154.0/25; # labs v4
      #       allow 193.136.154.128/26;# labs2 v4
      #       allow 2001:690:2100:84::/64; # labs v6
      #       deny all;
      #     }
      #   '';
      # };

      # Public but not listed, to share temporary files
      "~ ^/tmp" = {
        alias = "/mnt/data/ftp/tmp/";
        extraConfig = "autoindex off;";
      };
      # TODO: check addresses and stuff
      # "~ ^/priv" = {
      #   alias = "/mnt/data/ftp/priv/";
      #   extraConfig = ''
      #     # Allow access only from the RNL networks
      #     allow 193.136.164.0/24;
      #     allow 193.136.154.0/24;
      #     allow 10.16.80.0/24;
      #     allow 2001:690:2100:80::/58;
      #     deny all;
      #   '';
      # };
    };
  };
}
