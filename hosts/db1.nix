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
      "/dev/disk/by-id/ata-ADATA_SU900_2I2720066410"
      "/dev/disk/by-id/ata-ADATA_SU900_2I2720066486"
    ];
  };

  # Networking
  networking = {
    hostId = "127bc747"; # Randomly generated

    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "193.136.164.84";
          prefixLength = 26;
        }
      ];
    };

    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = "192.168.21.1";
          prefixLength = 29;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
  };

  users.users.root.hashedPassword = "$6$x2GVjFi0iJZCwQ2l$omZcbZkgxAtdc.oNda1AhdMEQizTAmEfNmHk6IKuGZoFMd.7Bf9mfWjF2gvQxIzwLtKxPmADSCk9FqQbH.C3E0";

  services.mysql.settings.mysqld.wsrep_node_address = "192.168.21.1";

  services.keepalived.vrrpInstances.db-clusterIP4.priority = 255;
}
