{ ... }:
{
  # Disable Node exporter
  services.prometheus.exporters.node.enable = false;

  rnl.labels.type = "ups";
}
