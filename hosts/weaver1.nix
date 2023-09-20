{
  config,
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    webserver
    weaver
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.89";
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
          address = "2001:690:2100:81::89";
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

  # Bind mount /var/lib/dokuwiki/wiki/data to /mnt/data/dokuwiki
  fileSystems."${config.services.dokuwiki.sites.wiki.stateDir}" = {
    device = "/mnt/data/dokuwiki/data";
    options = ["bind"];
  };
  fileSystems."${config.services.dokuwiki.sites.wiki.usersFile}" = {
    device = "/mnt/data/dokuwiki/users.auth.php";
    options = ["bind"];
  };

  rnl.internalHost = true;

  rnl.labels.location = "zion";

  rnl.storage.disks.data = ["/dev/vdb"];

  rnl.virtualisation.guest = {
    description = "Webserver interno";

    vcpu = 4;
    memory = 4096;

    interfaces = [{source = "priv";}];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/volumes/weaver1";
      }
      {
        source.dev = "/dev/zvol/dpool/data/weaver1";
      }
      {
        type = "file";
        source.file = "/mnt/data/weaver1_root.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/weaver1_shared.img";
      }
    ];
  };
}
