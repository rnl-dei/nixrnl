{ config, ... }:
let
  disks = config.rnl.storage.disks;

  mkRootDiskConfig = device: _index: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "512M";
          type = "EF00"; # for EFI System
          # NOTE: added name because I personally like that
          name = "btrfsboot";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          # 16G of swap
          end = "-16G";
          name = "btrfsroot";
          content = {
            type = "btrfs";
            mountpoint = "/";
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
        swap = {
          size = "100%"; # size = "16G";
          name = "btrfsswap";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
      };
    };
  };

  root = mkRootDiskConfig (builtins.elemAt disks.root 0) 0;
in
{
  disk = {
    inherit root;
  };
}
