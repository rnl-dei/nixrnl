{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  users.users.root.password = lib.mkForce null;
  services.getty.autologinUser = "root"; # Since VM root password is null, autologin is required

  rnl.storage.disks.root = lib.mkDefault [ "/dev/vda" ];

  services.qemuGuest.enable = true;

  rnl.labels.type = "vm";
}
