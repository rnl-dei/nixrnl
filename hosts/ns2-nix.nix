{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    ns.master
  ];
  rnl.virtualisation.guest = {
    description = "Secondary Name Server";
    createdBy = "francisco.martins";

    vcpu = 1;
    memory = 2048;
    interfaces = [ { source = "pub"; } ];
    disks = [
      # TODO RENAME DATA SET IN HYPERVISOR
      { source.dev = "/dev/zvol/dpool/data/ns2"; }
    ];
  };

  # Networking
  networking = {
    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.2";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::2";
          prefixLength = 64;
        }
      ];

    };
  };

  rnl.labels.location = "dredd";

}
