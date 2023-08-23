{
  config,
  lib,
  ...
}: let
  disks = config.rnl.storage.disks;

  mkRootDiskConfig = device: index: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "512M";
          type = "EF00"; # for EFI System
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        windows = {
          size = "200G";
        };
        linux = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  root = mkRootDiskConfig (builtins.elemAt disks.root 0) 0;
in {
  disk = {inherit root;};
}
