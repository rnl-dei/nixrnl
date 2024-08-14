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

    vault
    webserver
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.81";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::81";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  # Set storage config
  age.secrets."vault-storage.hcl" = {
    file = ../secrets/vault-storage-hcl.age;
    mode = "0400";
    owner = "vault";
    group = "vault";
  };

  services.vault.extraSettingsPaths = [config.age.secrets."vault-storage.hcl".path];

  rnl.db-cluster = {
    ensureDatabases = ["vault"];
    ensureUsers = [
      {
        name = "vault";
        ensurePermissions = {
          "vault.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Set Vault TLS certs
  age.secrets."vault.cer" = {
    file = ../secrets/vault-cer.age;
    mode = "0400";
    owner = config.services.nginx.user;
    group = config.services.nginx.group;
  };

  age.secrets."vault.key" = {
    file = ../secrets/vault-key.age;
    mode = "0400";
    owner = config.services.nginx.user;
    group = config.services.nginx.group;
  };

  services.nginx.virtualHosts.vault = {
    sslCertificate = config.age.secrets."vault.cer".path;
    sslCertificateKey = config.age.secrets."vault.key".path;
  };

  # Disable this since we're not using it yet
  services.keepalived.enable = false;

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Gestor de segredos e CA da RNL";

    interfaces = [{source = "priv";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/vault";}];
  };
}
