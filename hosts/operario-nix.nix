{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  rnl.labels.location = "atlas";

  rnl.virtualisation.guest = {
    description = "Runners Gitlab em NixOS";
    createdBy = "vasco.morais";

    #memory = 65536; # 64GB
    #cpu = 24;
    memory = 4096; # lets start with the requirements for our own worker
    cpu = 4;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:c1:d1:6a";
      }
    ];

    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/operario-nix"; }
    ];

  };

  networking = {
    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.182";
          prefixLength = 26;
        }
      ];

      ipv6.addresses = [
        {
          address = "2001:690:2100:83::182";
          prefixLength = 64;
        }
      ];

    };
  };

}
