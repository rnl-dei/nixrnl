{ lib, ... }:
{
  # Set fake root filesystem to allow for building
  fileSystems."/".device = "/dev/null";
  boot.loader.grub.enable = lib.mkForce false;

  # Disable RNL storage since layout is unknown
  rnl.storage.enable = lib.mkForce false;
}
