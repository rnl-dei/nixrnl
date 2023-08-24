{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Required for command-not-found to work using flakes
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
    ./ist-shell.nix
    ./cluster/client.nix
    ./graphical/labs.nix
    ./containers/podman.nix
    ./software/labs.nix
  ];

  programs.chromium = {
    enable = true;
    extraOpts = {
      "AuthServerAllowlist" = "*.tecnico.ulisboa.pt";
      "DisableAuthNegotiateCnameLookup" = true;
    };
  };

  programs.firefox = {
    enable = true;
    preferences = {
      "network.negotiate-auth.trusted-uris" = "tecnico.ulisboa.pt";
    };
  };

  # Clean subuids and gids on boot
  systemd.tmpfiles.rules = ["f+  /etc/subuid 0644 root root -" "f+  /etc/subgid 0644 root root -"];

  users.users.root.hashedPassword =
    "$y$j9T$kLiDSrbLRV1LUo5yxocDv.$v5cptSarCIF4y.h6R5JTl8TLgfncHE8ZXKignjsF2i2";

  # Disable Network Manager
  networking.networkmanager.enable = false;

  # Enable DHCP
  networking.useDHCP = lib.mkForce true;
  networking.dhcpcd.extraConfig = ''
    duid ll   # Allow DHCP server to assign a static IPv6 using the MAC address
  '';

  # RNL Virt
  environment.systemPackages = with pkgs; [rnl-virt];
  virtualisation.libvirtd.enable = true;

  environment.shellAliases = {
    reboot2Win = "${pkgs.grub2}/bin/grub-editenv /boot/grub/grubenv set count=1 && reboot"; # TODO receive count as an argument
    reboot2PXE = "${pkgs.grub2}/bin/grub-editenv /boot/grub/grubenv set entry=ipxe && reboot";
  };

  # Bootloader
  boot = {
    plymouth.enable = true;
    loader = {
      efi.canTouchEfiVariables = lib.mkForce true;
      grub = {
        efiInstallAsRemovable = false;
        extraConfig = ''
          # If count != 0 and isn't an empty string.
          if [ "x''${count}" != "x0" -a "x''${count}" != "x"]; then
            set default=1
          else
            set default=0
          fi

          # Count down the number of consecutive reboots.
          # FIXME do this in a proper way (with decrementation)
          if [ "x''${count}" = "x6" ]; then
            set count=5
            save_env --file /grub/grubenv count
          elif [ "x''${count}" = "x5" ]; then
            set count=4
            save_env --file /grub/grubenv count
          elif [ "x''${count}" = "x4" ]; then
            set count=3
            save_env --file /grub/grubenv count
          elif [ "x''${count}" = "x3" ]; then
            set count=2
            save_env --file /grub/grubenv count
          elif [ "x''${count}" = "x2" ]; then
            set count=1
            save_env --file /grub/grubenv count
          elif [ "x''${count}" = "x1" ]; then
            set count=0
            save_env --file /grub/grubenv count
          elif [ "x''${count}" != "x0" ]; then
            set count=0
            save_env --file /grub/grubenv count
          fi

          if [ "''${entry}" = "ipxe" ]; then
            set entry=""
            save_env --file /grub/grubenv entry
            menuentry --unrestricted "iPXE Boot" {
              chainloader /ipxe.efi
            }
          fi
        '';

        extraFiles = { "ipxe.efi" = "${pkgs.ipxe}/ipxe.efi"; };
        extraEntries = ''
          menuentry --unrestricted "Windows 10" {
            insmod part_gpt
            insmod fat
            search --fs-uuid --set=root $FS_UUID
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }

          # Intentianlly missing bracket so the configurations submenu is also inside Administration
          submenu "Administration" {
          menuentry "iPXE Boot" {
            chainloader /ipxe.efi
          }
        '';

        extraInstallCommands = ''
          sed -i 's/ - Default//g' /boot/grub/grub.cfg
          sed -i 's/NixOS/Linux/g' /boot/grub/grub.cfg
          echo "}" >> /boot/grub/grub.cfg
        '';

        splashImage = null;

        users.root.hashedPassword =
          "grub.pbkdf2.sha512.10000.616F635FFE748E06FC697DCC79BE6E5CF4923F8055B8776C70CE25FE89B0ACC10B27507B67CEED52A902609FEF8A91FA18A41D7A51E66FEFB199B6FBEF4E0ADA.5F1AA5C420F8AD6535E48F414955F22F64151DB9DCD5C5B2283D2507B7C3992A87EB8A08B6C6BD7CCB9F4E20F1A470EFC350E9592010E663E39BE34852DB2C24";
      };
    };
  };
}
