{
  config,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    monitoring.grafana
    monitoring.prometheus
  ];

  # Networking
  networking.hostId = "0725d120"; # Randomly generated
  networking = {
    interfaces.enp1s0 = {
      ipv4 = {
        addresses = [
          {
            address = "193.136.164.87";
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
      ipv6 = {
        addresses = [
          {
            address = "2001:690:2100:81::87";
            prefixLength = 64;
          }
        ];
        routes = [
          {
            address = "::";
            prefixLength = 0;
            via = "fe80::96f7:ad00:28af:fa13";
          }
        ];
      };
    };
    interfaces.mgmt = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.102.1";
            prefixLength = 22;
          }
        ];
        routes = [
          {
            address = "192.168.100.0";
            prefixLength = 22;
            via = "192.168.102.1";
          }
        ];
      };
    };
  };

  rnl.internalHost = true;

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "VM de teste migração Tardis";
    createdBy = "martim.monis";
    maintainers = ["rnl"];

    memory = 4096;
    vcpu = 4;

    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/tardis2";}
    ];
  };
}
