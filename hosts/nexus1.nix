{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    fail2ban
    ist-shell
    nexus
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.130";
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
          address = "2001:690:2100:83::130";
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

  # Prevent users from using up all the compute
  # reserves 10% of compute power for system processes
  systemd.slices."user".sliceConfig.CPUQuota = "${toString (config.rnl.virtualisation.guest.vcpu * 100 / 90)}%";

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Shell para alunos";
    createdBy = "nuno.alves";

    memory = 8192;
    vcpu = 8;

    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/nexus1";}];
  };
}
