{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.physical

    db-cluster
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage.disks = {
    root = [
      "/dev/disk/by-id/ata-ADATA_SU900_2J1020054958"
      "/dev/disk/by-id/ata-ADATA_SU900_2I2720065717"
    ];
  };

  # Networking
  networking = {
    hostId = "8f594e89"; # Randomly generated

    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "193.136.164.85";
          prefixLength = 26;
        }
      ];
    };

    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = "192.168.21.2";
          prefixLength = 29;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
  };

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;

  users.users.root.hashedPassword = "$6$SXhNKNopD9X7BSk6$dq4YIXjjfPLV2/UmbaDWmyjktrvICD1Ev7klg/dE1lFNo5pJZSYGqyCIsGiF6HHSpbP.s7/Isfrb8rW5usMH11";

  services.mysql.settings.mysqld.wsrep_node_address = "192.168.21.2";

  services.keepalived.vrrpInstances.db-clusterIP4.priority = 254;

  # Backups (Only DB2 does backups)
  rnl.mysqlBackup = {
    enable = true;
    databases = config.rnl.db-cluster.ensureDatabases;
    calendar = "02:30:00";
    deleteOldBackups = true;
    retentionDays = 7;
  };
}
