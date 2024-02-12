{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.90";
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
          address = "2001:690:2100:81::90";
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

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Gestão das VMs com ansible";
    createdBy = "nuno.alves";

    interfaces = [{source = "priv";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/dealer";}
      {
        type = "file";
        source.file = "/mnt/data/trantor.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/cerebro.img";
      }
    ];
  };
}
