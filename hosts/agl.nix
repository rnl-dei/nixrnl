{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.nixos
    type.vm

    fail2ban
    moodle
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.24";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::24";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";
  };

  # Bind mount /var/lib/moodle to /mnt/data/moodle
  fileSystems."/var/lib/moodle" = {
    device = "/mnt/data/moodle";
    options = ["bind"];
  };

  age.secrets."moodle-agl-db.password" = {
    file = ../secrets/moodle-agl-db-password.age;
    owner = "moodle";
    mode = "0400";
  };

  services.moodle = {
    database = {
      name = "staging_moodle_dei";
      user = "staging_moodle_dei";
      passwordFile = config.age.secrets."moodle-agl-db.password".path;
    };
  };
  rnl.db-cluster = let
    database = config.services.moodle.database.name;
    user = config.services.moodle.database.user;
  in {
    ensureDatabases = [database];
    ensureUsers = [
      {
        name = user;
        ensurePermissions = {
          "${database}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  rnl.internalHost = true;

  rnl.labels.location = "zion";

  rnl.storage.disks.data = ["/dev/vdb"];

  rnl.virtualisation.guest = {
    description = "Moodle @ DEI (Staging)";
    createdBy = "nuno.alves";
    maintainers = ["dei"];

    memory = 8192;
    vcpu = 8;

    interfaces = [{source = "pub";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/agl";}
      {source.dev = "/dev/zvol/dpool/data/agl";}
    ];
  };
}
