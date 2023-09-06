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

    cluster.server
    fail2ban
    ist-shell
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.138";
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
          address = "2001:690:2100:83::138";
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

  rnl.labels.location = "zion";

  # Crack down on compute-heavy tasks from users
  # reserves ~50% of compute-power for system processes
  systemd.slices."user".sliceConfig.CPUQuota = "${toString (config.rnl.virtualisation.guest.vcpu * 100 / 50)}%";

  rnl.virtualisation.guest = {
    description = "Cluster Server";
    createdBy = "nuno.alves";

    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/borg";}];
  };
}
