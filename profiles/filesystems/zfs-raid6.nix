{ config, lib, ... }:
{
  boot.loader.grub = {
    enable = lib.mkForce true; # Ensure that grub is enabled
    devices = lib.mkForce [ ];

    # Use mirrored boot even if we have only one disk
    mirroredBoots = lib.imap0 (i: device: {
      path = "/boot${lib.optionalString (i > 0) (toString i)}";
      devices = [ device ];
    }) config.rnl.storage.disks.root;
  };
  
  # Enable autoscrub to avoid bitrot
  services.zfs.autoScrub={
    enable = true;
    pools =[
      dpool
      rpool
    ];

  };

  # Use ZFS with mirror on root disks and raid6 on data disks
  rnl.storage.layout = lib.mkForce "zfs-raid6";
}
