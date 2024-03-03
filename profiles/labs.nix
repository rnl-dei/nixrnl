{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Required for command-not-found to work using flakes
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
    ./ist/shell.nix
    ./pull.nix
    ./cluster/client.nix
    ./graphical/labs.nix
    ./containers/podman/rootless.nix
    ./software/labs.nix
    ./transmission/labs.nix
  ];

  programs.nix-ld.enable = true;

  nix.settings = {
    substituters = [
      "https://proxy.cache.rnl.tecnico.ulisboa.pt?priority=38"
      "https://labs.cache.rnl.tecnico.ulisboa.pt?priority=39"
    ];

    trusted-public-keys = [
      "labs.cache.rnl.tecnico.ulisboa.pt:nqg28rqC5jNdevtd7DLIpvUPDBmv2D8hhWy0REBh5lU="
    ];
  };

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

  # Allow the using of smartcards
  services.pcscd.enable = true;

  # Clean subuids and gids on boot
  systemd.tmpfiles.rules = ["f+  /etc/subuid 0644 root root -" "f+  /etc/subgid 0644 root root -"];

  users.users.root.hashedPassword = "$y$j9T$kLiDSrbLRV1LUo5yxocDv.$v5cptSarCIF4y.h6R5JTl8TLgfncHE8ZXKignjsF2i2";

  # Disable immediate shutdown when power button is pressed
  services.logind.extraConfig = "HandlePowerKey=ignore";

  # Allow profiling of system metrics (Required to the CPD course)
  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = 0;
    "kernel.kptr_restrict" = 0;
  };

  # Disable Network Manager
  networking.networkmanager.enable = false;

  # Enable DHCP
  networking.useDHCP = lib.mkForce true;
  networking.dhcpcd.extraConfig = ''
    duid ll   # Allow DHCP server to assign a static IPv6 using the MAC address
  '';

  # Disable firewall, to simplify everyone's life
  networking.firewall.enable = lib.mkForce false;

  age.secrets."netrc" = {
    file = ../secrets/open-sessions-key.age;
    mode = "0400";
    path = "/etc/open-sessions/netrc";
  };

  # RNL Virt / Reboot2
  environment.systemPackages = with pkgs; [rnl-virt reboot2];
  virtualisation.libvirtd.enable = true;

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
        extraEntries = ''
          menuentry --unrestricted "Windows 10" {
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }

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

  # Open Sessions
  systemd.services."sessioncontrol" = {
    description = "RNL session control";
    requires = ["network-online.target"];
    after = ["network.target" "network-online.target"];
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      ExecStart = "${pkgs.opensessions-scripts}/bin/session-control.sh boot";
      ExecStop = "${pkgs.opensessions-scripts}/bin/session-control.sh shutdown";
    };
    wantedBy = ["multi-user.target"];
  };

  # Add after run ist-shell scripts
  security.pam.services.login.text = lib.mkDefault (lib.mkOrder 2000 ''
    session optional pam_exec.so ${pkgs.opensessions-scripts}/bin/session-control.sh
  '');
  security.pam.services.sshd.text = lib.mkDefault (lib.mkOrder 2000 ''
    session optional pam_exec.so ${pkgs.opensessions-scripts}/bin/session-control.sh
  '');

  # Windows Deploy
  rnl.windows-labs = {
    enable = true;
    package = config.services.transmission.settings.download-dir + "/rnl-windows-labs";
    keyFile = config.age.secrets."windows-labs-image.key".path;
  };

  age.secrets."windows-labs-image.key" = {
    file = ../secrets/windows-labs-image-key.age;
    owner = "root";
    mode = "0400";
  };
}
