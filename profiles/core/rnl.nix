{
  pkgs,
  lib,
  config,
  ...
}: let
  RNLCert = builtins.fetchurl {
    url = "https://rnl.tecnico.ulisboa.pt/ca/cacert/cacert.pem";
    sha256 = "Qg7e7LIdFXvyh8dbEKLKdyRTwFaKSG0qoNN4KveyGwg=";
  };

  SSHTrustedCA = builtins.fetchurl {
    url = "https://vault.rnl.tecnico.ulisboa.pt/v1/ssh-client-signer/public_key";
    sha256 = "1dizakgfzr5khi73mpwr4iqhmbkc82x9jswfm8kgzysgqwn6cz6c";
  };
in {
  imports = [./common.nix];

  environment = {
    systemPackages = with pkgs; [
      # Editors
      nano
      neovim
      vim

      # Networking
      iproute2
      netcat-gnu
      tcpdump

      # Misc
      tmux
      tree
      molly-guard # Prevents accidental shutdowns/reboots
    ];
  };

  # Configure base network
  networking = {
    domain = "rnl.tecnico.ulisboa.pt";
    firewall.enable = true;
    useDHCP = false;
    nameservers = ["193.136.164.1" "193.136.164.2" "2001:690:2100:82::1" "2001:690:2100:82::2"];
    search = ["rnl.tecnico.ulisboa.pt"];
  };

  # Set issue message
  environment.etc."issue".text = lib.mkDefault ''
    \e[1;31m« Welcome to ${config.networking.hostName} @ RNL »\e[0m
  '';

  # Configure shell
  programs.bash = {
    enableCompletion = true;
    enableLsColors = true;
    # TODO: Add auto logout on tty[1-6] after 30 minutes of inactivity
  };
  users.defaultUserShell = lib.mkForce pkgs.bashInteractive;

  # Configure OpenSSH
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      # UseDNS = true;
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    extraConfig = lib.mkOrder 10 ''
      # Allow login using Vault signed certificates
      TrustedUserCAKeys ${SSHTrustedCA}

      # Allow admin network to login as root
      Match Address 193.136.164.192/27,2001:690:2100:82::/64,192.168.20.0/24
        PermitRootLogin without-password
    '';
  };

  # Configure users
  users.mutableUsers = false; # Disable manual user management
  users.users.root = {
    description = lib.mkForce "Root user to be used by RNL admins";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps @torvalds" # TODO: Replace with RNL key
    ];
  };

  # Configure email
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      from = "%U@%C.rnl.tecnico.ulisboa.pt";
    };
    accounts = {
      "default" = {
        host = "comsat.rnl.tecnico.ulisboa.pt";
        port = 25;
        tls = "off";
        tls_starttls = "off";
      };
    };
  };

  # Add certificates
  security.pki.certificateFiles = ["${RNLCert}"];

  # Configure node exporter
  services.prometheus.exporters.node = {
    enable = lib.mkDefault true;
    openFirewall = true;
  };

  # Configure bootloader
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  system.stateVersion = "23.05";
}
