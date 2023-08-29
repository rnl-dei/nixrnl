{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.windows-labs;
in {
  options.rnl.windows-labs = {
    enable = mkEnableOption "RNL Windows Labs";
    package = mkOption {
      type = types.package;
      default = pkgs.rnl-windows-labs;
      description = "The package to deploy with Windows Image and GRUB files";
    };
    image = mkOption {
      type = types.path;
      default = cfg.package + "/windows10-partition.img.zst.gpg";
      description = "The path to the Windows partition image";
    };
    extraFiles = mkOption {
      type = types.attrsOf types.path;
      default = {
        "EFI/Microsoft/Boot/BCD" = cfg.package + "/BCD";
        "EFI/Microsoft/Boot/bootmgfw.efi" = cfg.package + "/bootmgfw.efi";
      };
      description = "The extra files to copy to the EFI partition";
    };
    keyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The path to the file containing the password to decrypt the image";
    };
    partition = mkOption {
      type = types.str;
      default = "/dev/sda2";
      description = "The path to the partition to mount";
    };
    compression = mkOption {
      type = types.enum ["none" "zstd" "gpg-zstd"];
      default = "gpg-zstd";
      description = "The compression algorithm to use when writing the image";
    };
    bs = mkOption {
      type = types.str;
      default = "1M";
      description = "The block size to use when writing the image";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.loader.grub.enable;
        message = "The GRUB bootloader is required to deploy Windows";
      }
      {
        assertion = cfg.compression == "gpg-zstd" && cfg.keyFile != null;
        message = "The key file is required to decrypt the image";
      }
    ];

    # Use this files on extra entries
    boot.loader.grub = {
      extraPrepareConfig = ''
        mkdir -p /boot/EFI/Microsoft/Boot
      '';
      extraFiles = cfg.extraFiles;
    };

    systemd.services."rnl-windows-labs" = {
      description = "Deploy Windows image to partition";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
      };
      script = ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Check if partition have filesystem
        if [ ! -z `${pkgs.util-linux}/bin/blkid -s TYPE -o value ${cfg.partition}` ]; then
          echo "Partition ${cfg.partition} possibly have Windows installed."
          echo "If you want to reinstall Windows, please format the partition"
          echo "using the following command: wipefs -a ${cfg.partition}"
          echo "and then restart the service."
          exit 0
        fi

        # Write image to partition
        echo "Writing image to partition ${cfg.partition}"

        # Decompress image
        if [ "${cfg.compression}" = "zstd" ]; then
          ${pkgs.zstd}/bin/unzstd ${cfg.image} | dd of=${cfg.partition} bs=${cfg.bs} status=progress
        elif [ "${cfg.compression}" = "gpg-zstd" ]; then
          cat ${cfg.keyFile} | ${pkgs.gnupg}/bin/gpg --batch --passphrase-fd 0 --decrypt ${cfg.image} | \
          ${pkgs.zstd}/bin/unzstd | \
          dd of=${cfg.partition} bs=${cfg.bs} status=progress
        else
          dd if=${cfg.image} of=${cfg.partition} bs=${cfg.bs} status=progress
        fi

        echo "Windows image successfully deployed to partition ${cfg.partition}"
        exit 0
      '';
    };
  };
}
