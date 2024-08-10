{
  config,
  lib,
  ...
}: {
  assertions = [
    {
      assertion = config.users.users.root.hashedPassword != null;
      message = "Root password must be set";
    }
  ];

  boot.loader.systemd-boot.enable = false;

  # Use GRUB by default at physical hosts
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    configurationLimit = lib.mkDefault 5;

    # The reasons to enable the option below are:
    # - We simply dislike the idea of depending on NVRAM state to make your drive bootable
    # - You are installing NixOS and want it to boot in UEFI mode, but you are currently booted in legacy mode
    efiInstallAsRemovable = lib.mkDefault true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  # Generic kernel modules to support everything
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ehci_pci" "mpt3sas" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" "isci"];

  # Enable HDD/SSD temperature monitoring
  hardware.sensor.hddtemp = {
    enable = true;
    drives = lib.mkDefault ["/dev/sd?" "/dev/nvme?"];
    unit = "C";
  };

  rnl.labels.type = lib.mkDefault "physical";
}
