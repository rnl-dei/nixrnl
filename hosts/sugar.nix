{ lib, profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.unknown
    os.ubuntu
    type.hypervisor
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Networking
  networking = {
    interfaces.enp5s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.148";
          prefixLength = 26;
        }
      ];
    };

    defaultGateway.address = "193.136.164.190";
  };

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;

  # Disable SMART monitoring
  services.prometheus.exporters.smartctl.enable = lib.mkForce false;

  # Disable Node Exporter
  services.prometheus.exporters.node.enable = lib.mkForce false;
}
