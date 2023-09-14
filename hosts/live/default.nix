{
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.nixos
  ];

  rnl.storage.enable = lib.mkForce false;
  rnl.labels = {
    type = null;
    location = null;
  };

  # Disable root SSH via password
  services.openssh.settings.PermitRootLogin = lib.mkForce "without-password";

  # Disable nixos autologin and set root as autologin user
  services.getty.autologinUser = lib.mkForce "root";

  # Disable Node exporter
  services.prometheus.exporters.node.enable = false;

  # Change default TTL value in order to allow Grafana to detect the live host
  # This is useful for OS detection
  # (Reminder: every hop will decrease the TTL value by 1)
  boot.kernel.sysctl."net.ipv4.ip_default_ttl" = 32;
}
