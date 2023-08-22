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
}
