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
    description = "Name Server";
    createdBy = "francisco.martins";

    vcpu = 1;
    memory = 2048;
    interfaces = [ { source = "pub"; } ];
    disks = [
      { source.dev = "/dev/zvol/dpool/data/ns3"; }
    ];
  };

  # Networking
  networking = {
    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.99";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::99";
          prefixLength = 64;
        }
      ];

    };
  };

  rnl.labels.location = "dredd";
  age.secrets."root-at-ns3-ssh.key" = {
    file = ../secrets/root-at-ns3-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

}
