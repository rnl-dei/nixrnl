{ config, lib, ... }:
let
  disks = config.rnl.storage.disks;

  mkRootDiskConfig = device: index: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        mbr = {
          size = "1M";
          type = "EF02"; # for BIOS boot
        };
        boot = {
          size = "512M";
          type = "EF00"; # for EFI System
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot${lib.optionalString (index > 0) (toString index)}";
            mountOptions = [
              "defaults"
              "nofail"
            ];
          };
        };
        rpool = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "rpool";
          };
        };
      };
    };
  };

  mkDataDiskConfig = device: _index: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        dpool = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "dpool";
          };
        };
      };
    };
  };

  root = builtins.listToAttrs (
    lib.imap0 (i: device: {
      name = "root-${toString i}";
      value = mkRootDiskConfig device i;
    }) disks.root
  );

  data = builtins.listToAttrs (
    lib.imap0 (i: device: {
      name = "data-${toString i}";
      value = mkDataDiskConfig device i;
    }) disks.data
  );

  zfsDefaultOptions = {
    options = {
      ashift = "12";
      autotrim = "on";
    };

    rootFsOptions = {
      acltype = "posixacl";
      atime = "off";
      canmount = "off";
      compression = "zstd";
      dnodesize = "auto";
      normalization = "formD";
      xattr = "sa";
      mountpoint = "none";
      # "com.sun:auto-snapshot" = "false";
    };
  };
in
{
  disk = root // data;

  zpool.rpool = zfsDefaultOptions // {
    type = "zpool";
    mode = "mirror";
    datasets = {
      root = {
        type = "zfs_fs";
        mountpoint = "/";
      };
      reserved = {
        type = "zfs_fs";
        options.refreservation = "10G";
      };
    };
  };

  zpool.dpool = zfsDefaultOptions // {
    type = "zpool";
    mode = "raidz1"; # RAID 5
    datasets = {
      data = {
        type = "zfs_fs";
        mountpoint = "/mnt/data";
      };
      volumes = {
        type = "zfs_fs";
      };
      reserved = {
        type = "zfs_fs";
        options.refreservation = "10G";
      };
    };
  };
}
