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
            mountOptions = ["defaults"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["defaults"];
          };
        };
      };
    };
  };

  mkDataDiskConfig = device: index: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/mnt/data${lib.optionalString (index > 0) (toString index)}";
          };
        };
      };
    };
  };

  root = mkRootDiskConfig (builtins.elemAt disks.root 0) 0;

  data = builtins.listToAttrs (lib.imap0 (
      i: device: {
        name = "data-${toString i}";
        value = mkDataDiskConfig device i;
      }
    )
    disks.data);
in {
  disk = {inherit root;} // data;
}
