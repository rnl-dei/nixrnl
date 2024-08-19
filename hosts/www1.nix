{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    www
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.9";
          prefixLength = 26;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.62";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:80::9";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:80::ffff:1";
        }
      ];
    };
  };

  # Set as primary
  services.keepalived.vrrpInstances = {
    wwwIP4.priority = 255;
    wwwIP6.priority = 255;
  };

  # Bind mount /mnt/data/forum to /var/www/forum
  fileSystems."${config.services.nginx.virtualHosts.forum.root}" = {
    device = "/mnt/data/forum";
    options = ["bind"];
  };

  rnl.labels.location = "chapek";

  rnl.storage.disks.data = ["/dev/vdb"];

  rnl.virtualisation.guest = {
    description = "Webserver da RNL";

    vcpu = 4;

    interfaces = [{source = "pub";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/www1";}
      {source.dev = "/dev/zvol/dpool/data/www1";}

      {
        type = "file";
        source.file = "/mnt/data/www1.img";
      }
    ];
  };
}
