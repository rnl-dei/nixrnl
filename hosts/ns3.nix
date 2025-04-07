{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    ns.slave
  ];
  rnl.virtualisation.guest = {
    description = "Name Server";
    createdBy = "francisco.martins";

    vcpu = 1;
    memory = 2048;
    interfaces = [ { source = "pub"; } ];
    disks = [
      #{ source.dev = "/dev/zvol/dpool/volumes/hedgedoc"; }
      { source.dev = "/dev/zvol/dpool/data/ns3"; }
    ];
  };

  # Networking
  #TODO
  networking = {
    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.99";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::99";
          prefixLength = 64;
        }
      ];

    };
  };

  rnl.labels.location = "dredd";

  #  rnl.storage.disks.data = [ "/dev/vdb" ];

}
