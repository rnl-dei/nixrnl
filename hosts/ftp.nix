{
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6-full
    os.nixos
    type.physical

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
}
