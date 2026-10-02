{ ... }:
{
  rnl.storage = {
    enable = true;
    layout = "uefi-btrfs-swap";
  };

  # Use GRUB with a simple UEFI layout.
  boot.loader.grub.device = "nodev";

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
