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

    webserver
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.165";
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
          address = "2001:690:2100:83::165";
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

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "VM de testes para o DEI";
    createdBy = "nuno.alves";
    maintainers = ["dei"];

    vcpu = 4;
    memory = 4096;

    interfaces = [{source = "dmz";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/blatta";}
      {
        type = "file";
        source.file = "/mnt/data/blatta.img";
      }
    ];
  };

  rnl.internalHost = true;

  # Services
  dei.dms = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSDnfYmzk0zCktsKjRAphZavsDwXG/ymq+STFff1Zy/" # GitLab CI
    ];
    sites = {
      staging = {
        enable = true;
        serverName = "dms.${config.networking.fqdn}";
      };
    };
  };
}
