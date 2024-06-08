{
  config,
  lib,
  profiles,
  pkgs,
  ...
}: {
  imports = with profiles; [graphical.labs];

  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    emacs
    sublime
    codeblocksFull
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-vscode.cpptools
      ];
    })

    # Compilers
    gcc13
    gdb

    # Browser
    firefox
  ];

  users.users.oni = {
    isNormalUser = true;
    password = "oni";
    description = "Olimpíadas Nacionais de Informática";
  };

  users.users.root.hashedPassword = "$6$8DuWLv1aIpHE3IcX$qT460.hYoMyak/cQpfpZRsMpzIvaXYbnRT7z7wUPWphOdqSrcmaBV1v0WzCyPYlzTyZEHVnk/Piv4cMFZpekb0";

  # Disable Network Manager
  networking.networkmanager.enable = false;

  # Enable DHCP
  networking.useDHCP = lib.mkForce true;
  networking.dhcpcd.extraConfig = ''
    duid ll   # Allow DHCP server to assign a static IPv6 using the MAC address
  '';

  # Disable Nix
  nix.settings.allowed-users = ["root"];

  # Firewall
  networking.firewall.enable = lib.mkForce false;
  networking.nftables = {
    enable = true;
    preCheckRuleset = ''
      sed 's/skuid squid/skuid nobody/g' -i ruleset.conf
    '';
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0;

          # accept any localhost traffic
          iifname lo accept

          # accept traffic originated from us
          ct state {established, related} accept

          # accept SSH connections (required for a server)
          tcp dport 22 accept

          # accept node-exporter
          tcp dport 9100 accept

          # Allow ICMP
          ip protocol icmp accept

          drop
        }

        # Outgoing connections
        chain output {
          type filter hook output priority 0;

          # accept any localhost traffic
          iifname lo accept
          ip daddr 127.0.0.0/8 accept

          # accept traffic originated from us
          ct state {established, related} accept

          # Allow DNS
          ip daddr 193.136.164.1 udp dport domain accept
          ip daddr 193.136.164.2 udp dport domain accept

          # NTP
          ip daddr 193.136.164.4 udp dport ntp accept

          meta skuid root accept
          tcp dport {http, https} meta skuid squid accept

          drop
        }

      }
    '';
  };

  # Squid
  services.squid = {
    enable = true;
    proxyAddress = "127.0.0.1";
    package = pkgs.allowSquid.squid;
    configText = ''
      ssl_bump bump all

      # Mooshak
      acl whitelistdomain dstdomain mooshak.dcc.fc.up.pt

      acl safeports port 80 # http
      acl safeports port 443 # https

      http_access deny !safeports
      http_access allow whitelistdomain

      # Deny all by default
      http_access deny all

      # Application logs to syslog, access and store logs have specific files
      cache_log       syslog
      access_log      stdio:/var/log/squid/access.log
      cache_store_log stdio:/var/log/squid/store.log

      # Run as user and group squid
      cache_effective_user squid squid

      # Required by systemd service
      pid_filename /run/squid.pid

      # Squid port
      http_port ${toString config.services.squid.proxyPort}

      # Disable cache
      cache deny all
    '';
  };

  networking.proxy = let
    address = config.services.squid.proxyAddress;
    port = toString config.services.squid.proxyPort;
  in {
    httpProxy = "http://${address}:${port}";
    httpsProxy = "http://${address}:${port}";
  };

  rnl.wallpaper.defaultWallpaper = pkgs.rnlWallpapers.oni2024;

  programs.firefox = let
    mooshakURL = "https://mooshak.dcc.fc.up.pt/~oni-judge/";
  in {
    enable = true;
    preferences = {
      "browser.startup.homepage" = mooshakURL;
    };
    policies = {
      Bookmarks = [
        {
          Title = "Mooshak ONI";
          URL = mooshakURL;
          Placement = "toolbar";
        }
      ];
      DisplayBookmarksToolbar = true;
      OverrideFirstRunPage = mooshakURL;
    };
  };

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

  # Change TTL to identify ONI machines
  boot.kernel.sysctl."net.ipv4.ip_default_ttl" = 126;
}
