{ profiles, ... }:
{
  imports = with profiles; [
    core.dsi
    filesystems.unknown
    os.debian
    type.generic
  ];

  rnl.labels.location = "dsi";

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;
}
