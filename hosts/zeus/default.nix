{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.junos
    type.router
  ];

  # Disable Node exporter
  services.prometheus.exporters.node.enable = false;

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;

  rnl.labels.location = "inf1-p01-a1";
}
