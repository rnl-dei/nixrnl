{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    hedgedoc
  ];

  # Networking
  networking = {
    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.109";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::109";
          prefixLength = 64;
        }
      ];

    };
  };

  rnl.labels.location = "dredd";

  rnl.storage.disks.data = [ "/dev/vdb" ];

  rnl.virtualisation.guest = {
    description = "Hedgedoc machine";
    createdBy = "vasco.morais";

    vcpu = 1;

    interfaces = [ { source = "priv"; } ];
    disks = [
      #{ source.dev = "/dev/zvol/dpool/volumes/hedgedoc"; }
      { source.dev = "/dev/zvol/dpool/data/hedgedoc"; }
    ];
  };
}
