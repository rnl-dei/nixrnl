{
  profiles,
  lib,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
  ];

  rnl.storage.disks.root = ["/dev/sda"]; # Change this if needed
  rnl.labels.location = null;

  # Disable services that are not needed in generic labs
  systemd.services."sessioncontrol".enable = lib.mkForce false;
  services.transmission.enable = lib.mkForce false;
  rnl.windows-labs.enable = lib.mkForce false;

  # Disable ping monitoring
  rnl.monitoring.ping = false;
}
