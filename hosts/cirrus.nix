{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  #Networking
  networking = {

    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.38";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::38";
          prefixLength = 64;
        }
      ];
    };
  };

  age.secrets.ceph = {
    file = ../secrets/ceph-secret.age;
    mode = "600";
  };

  rnl.nfs = {
    enable = true;
    cephSecretPath = config.age.secrets.ceph.path;
  };

  rnl.labels.location = "neo";
  rnl.virtualisation.guest = {
    description = "Servidor de NFS. Interage com ceph.";
  };

}
