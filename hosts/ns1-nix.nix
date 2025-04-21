{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    #ns.master
  ];
  rnl.virtualisation.guest = {
    description = "Primary Name Server";
    createdBy = "francisco.martins";

    vcpu = 1;
    memory = 1024;
    interfaces = [ { source = "pub"; } ];
    disks = [
      { source.dev = "/dev/zvol/dpool/data/ns1"; }
    ];
  };

  # Networking
  networking = {
    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.1";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::1";
          prefixLength = 64;
        }
      ];

    };
  };

  rnl.labels.location = "chapek";

}
