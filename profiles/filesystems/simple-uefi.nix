{...}: {
  rnl.storage = {
    enable = true;
    layout = "simple-uefi";
  };

  # Use GRUB with a simple UEFI layout.
  boot.loader.grub.device = "nodev";
}
