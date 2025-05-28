{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid5
    os.nixos
    type.physical

    backups-server
  ];

  rnl.labels.location = "inf3-p2-admin";

  # Storage
  rnl.storage.disks = {
    root = [
      "/dev/disk/by-id/ata-WDC_WDS100T1R0A-68A4W0_235117800243"
      "/dev/disk/by-id/ata-WDC_WDS100T1R0A-68A4W0_23510Z802102"
    ];
    data = [
      "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5EG5L"
      "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5PAJL"
      "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5SWDL"
      "/dev/disk/by-id/ata-WDC_WD6003FRYZ-01F0DB0_V9H5PBEL"
    ];
  };

  # Networking
  networking.hostId = "33ac0996";
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.65";
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
          address = "2001:690:2100:81::3";
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

  users.users.root.hashedPassword = "$y$j9T$2YHEln/13WMdXzEZ7zNy71$6K3diCQ.XdiMKuhRTrrTGyw/avGtlxupZcP3gN7lzFB";

  age.secrets."syncoid-at-caixote-ssh.key" = {
    file = ../secrets/syncoid-at-caixote-ssh-key.age;
    owner = config.services.syncoid.user;
    group = config.services.syncoid.group;
  };
  services.syncoid.sshKey = config.age.secrets."syncoid-at-caixote-ssh.key".path;
}
