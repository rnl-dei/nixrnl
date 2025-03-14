{ profiles, lib, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
  ];

  rnl.storage.disks.root = [ "/dev/sda" ]; # Change this if needed
  rnl.labels.location = null;

  # Disable services that are not needed in generic labs
  systemd.services."sessioncontrol".enable = lib.mkForce false;
  services.transmission.enable = lib.mkForce false;
  rnl.windows-labs.enable = lib.mkForce false;

  # Disable ping monitoring
  rnl.monitoring.ping = false;

  users.users.exo = {
    isNormalUser = true;
    description = "Simple user to run exo";
  };

  systemd.services.exo = {
    description = "exo";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      CPU = "1";
    };
    serviceConfig = {
      User = "exo";
      Type = "simple";
      ExecStart = "${pkgs.exo}/bin/exo";
      Restart = "always";
    };
  };
}
