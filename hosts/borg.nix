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
    ist.shell
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

  services.slurm.dbdserver.storagePassFile = config.age.secrets."slurmdbd-borg-db.password".path;

  age.secrets."slurmdbd-borg-db.password" = {
    file = ../secrets/slurmdbd-borg-db-password.age;
    owner = "slurm";
  };

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Cluster Server";
    createdBy = "nuno.alves";

    vcpu = 4;
    memory = 8192; # 8GiB
    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/borg";}];
  };
}
