{ profiles, ... }:
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

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;

  users.users.root.hashedPassword = "$y$j9T$XVc15CHspL.GfxlaAg3q0.$cQ35fQkTWyG/q674Ikf2IL67rSFlvE34FmgMOPhZEt6";

  services.mysql.settings.mysqld.wsrep_node_address = "192.168.21.1";

  services.keepalived.vrrpInstances.db-clusterIP4.priority = 255;
}
