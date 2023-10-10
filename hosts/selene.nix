{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    webserver
    ist-delegate-election
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.146";
          prefixLength = 26;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.190";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:83::146";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:83::ffff:1";
        }
      ];
    };
  };

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "IST Delegate Election system";
    createdBy = "nuno.alves";

    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/selene";}];
  };
}
