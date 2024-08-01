{profiles, ...}: {
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
      ipv4 = {
        addresses = [
          {
            address = "193.136.164.85";
            prefixLength = 26;
          }
        ];
        routes = [
          {
            address = "0.0.0.0";
            prefixLength = 0;
            via = "193.136.164.126";
          }
        ];
      };
    };

    interfaces.eno2 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.21.2";
            prefixLength = 29;
          }
        ];
        routes = [
          {
            address = "192.168.21.0";
            prefixLength = 29;
            via = "193.136.164.1";
          }
        ];
      };
    };
  };

  users.users.root.hashedPassword = "$6$ccL2xTFm5fCydJGv$A7WvKxqp/FIeMYgJuWCkWLssjssyxRolfk7hC0BzIy7bXOa3V0Q.spALXVHJCXu5v9K7NnlYb9eyfbLPrBMNR1";

  services.mysql.settings.mysqld.wsrep_node_address = "192.168.21.2";

  services.keepalived.vrrpInstances.db-clusterIP4.priority = 254;
}
