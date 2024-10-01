{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./physical.nix];

  rnl.labels.type = "lab";

  # Bootloader
  boot = {
    supportedFilesystems = ["ntfs"];
    plymouth.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkForce true;
      grub = {
        efiInstallAsRemovable = false;
        configurationName = "Linux";
        extraConfig = ''
          # Count down the number of consecutive reboots.
          if [ "x''${count}" = "x5" ]; then
            set count=4
          elif [ "x''${count}" = "x4" ]; then
            set count=3
          elif [ "x''${count}" = "x3" ]; then
            set count=2
          elif [ "x''${count}" = "x2" ]; then
            set count=1
          elif [ "x''${count}" = "x1" ]; then
            set count=0
          else
            set count=0
            set entry=""
          fi

          # Save the number of consecutive reboots and the entry name.
          save_env --file /grub/grubenv count
          save_env --file /grub/grubenv entry

          if [ "''${entry}" = "pxe" ]; then
            menuentry --unrestricted "iPXE Boot" {
              chainloader /ipxe.efi
            }
          elif [ "''${entry}" = "windows" ]; then
            menuentry --unrestricted "Windows 10" {
              chainloader /EFI/Microsoft/Boot/bootmgfw.efi
            }
          fi
        '';

        extraFiles = {"ipxe.efi" = "${pkgs.ipxe}/ipxe.efi";};
        extraEntries =
          (lib.optionalString config.rnl.windows-labs.enable ''
            menuentry --unrestricted "Windows 10" {
              chainloader /EFI/Microsoft/Boot/bootmgfw.efi
            }
          '')
          + ''

            # Intentianlly missing bracket so the configurations submenu is also inside Administration
            submenu "Administration" {
            menuentry "iPXE Boot" {
              chainloader /ipxe.efi
            }

            # Easy way to clean the counter
            menuentry "Clean counter" {
              set count=0
              save_env --file /grub/grubenv count
            }
          '';

        extraInstallCommands = ''
          # Workaround to change default entry name
          # See issue: https://github.com/NixOS/nixpkgs/issues/15416
          ${pkgs.gnused}/bin/sed -i 's/"NixOS - Default"/"${config.boot.loader.grub.configurationName}"/g' /boot/grub/grub.cfg

          # Workaround to hide old NixOS entries in Administration submenu
          echo "}" >> /boot/grub/grub.cfg
        '';

        splashImage = null;

        users.root.hashedPassword = "grub.pbkdf2.sha512.10000.616F635FFE748E06FC697DCC79BE6E5CF4923F8055B8776C70CE25FE89B0ACC10B27507B67CEED52A902609FEF8A91FA18A41D7A51E66FEFB199B6FBEF4E0ADA.5F1AA5C420F8AD6535E48F414955F22F64151DB9DCD5C5B2283D2507B7C3992A87EB8A08B6C6BD7CCB9F4E20F1A470EFC350E9592010E663E39BE34852DB2C24";
      };
    };
  };
}
