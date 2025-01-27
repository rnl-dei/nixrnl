{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    fail2ban
    ist.shell
    nexus
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.131";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:83::131";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";
  };

  # Set as slave
  services.keepalived.vrrpInstances = {
    nexusIP4.priority = 254;
    nexusIP6.priority = 254;
  };

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Shell para alunos (Backup)";
    createdBy = "nuno.alves";

    memory = 8192;
    vcpu = 8;

    interfaces = [ { source = "dmz"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/nexus2"; } ];
  };
}
