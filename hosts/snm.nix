{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    snm
  ];

  #Networking
  networking = {

    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";

    interfaces.enp9s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.40";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::40";
          prefixLength = 64;
        }
      ];
    };
  };

  rnl.labels.location = "neo";
  rnl.virtualisation.guest = {
    description = "Servidor de Email";
  };
}
