{
  config,
  lib,
  ...
}: {
  # TODO: Configure zed

  # Enable zram swap
  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };

  boot = {
    supportedFilesystems = ["zfs"];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  };

  boot.zfs.devNodes = "/dev/disk/by-partlabel"; # Disko uses partlabel
  boot.zfs.forceImportRoot = lib.mkForce false; # Disable this by recomendation

  # Use simple zfs layout
  rnl.storage = {
    enable = true;
    layout = "zfs";
  };
}
