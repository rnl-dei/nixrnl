{...}: {
  rnl.storage = {
    enable = true;
    layout = "labs";
  };

  boot.loader.grub.device = "nodev";
}
