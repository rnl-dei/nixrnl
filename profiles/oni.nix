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

  # Change TTL to identify ONI machines
  boot.kernel.sysctl."net.ipv4.ip_default_ttl" = 126;
}
