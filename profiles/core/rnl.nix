{
  pkgs,
  lib,
  config,
  ...
}: let
  RNLCert = builtins.fetchurl {
    url = "https://rnl.tecnico.ulisboa.pt/ca/cacert/cacert.pem";
    sha256 = "1jiqx6s86hlmpp8k2172ki6b2ayhr1hyr5g2d5vzs41rnva8bl63";
  };

  SSHTrustedCA = builtins.fetchurl {
    url = "https://vault.rnl.tecnico.ulisboa.pt/v1/ssh-client-signer/public_key";
    sha256 = "1dizakgfzr5khi73mpwr4iqhmbkc82x9jswfm8kgzysgqwn6cz6c";
  };
in {
  environment = {
    systemPackages = with pkgs; [
      # Editors
      nano

      # Networking
      iproute2
      netcat-gnu
      tcpdump

      # Misc
      curl
      file
      git
      jq
      lsof
      molly-guard # Prevents accidental shutdowns/reboots
      ripgrep
      rsync
      strace
      tree
      whois
    ];

    variables = {
      HISTTIMEFORMAT = "%d/%m/%y %T ";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.htop = {
    enable = true;
    settings = {
      show_program_path = false;
      hide_kernel_threads = true;
      hide_userland_threads = true;
    };
  };

  programs.tmux = {
    enable = true;
  };

  # Configure base network
  networking = {
    domain = config.rnl.domain;
    firewall.enable = true;
    useDHCP = false;
    nameservers = ["193.136.164.1" "193.136.164.2" "2001:690:2100:82::1" "2001:690:2100:82::2"];
    search = [config.rnl.domain];
  };

  # Configure NTP
  time.timeZone = "Europe/Lisbon";
  networking.timeServers = ["ntp.rnl.tecnico.ulisboa.pt"];

  # Configure locale
  console.keyMap = "pt-latin9";
  services.xserver.layout = "pt,us";
  i18n = {
    defaultLocale = "en_US.utf8";
    extraLocaleSettings = {
      LC_ADDRESS = "pt_PT.utf8";
      LC_IDENTIFICATION = "pt_PT.utf8";
      LC_MEASUREMENT = "pt_PT.utf8";
      LC_MONETARY = "pt_PT.utf8";
      LC_NAME = "pt_PT.utf8";
      LC_NUMERIC = "pt_PT.utf8";
      LC_PAPER = "pt_PT.utf8";
      LC_TELEPHONE = "pt_PT.utf8";
      LC_TIME = "pt_PT.utf8";
    };
  };

  # Set issue message
  environment.etc."issue".text = lib.mkDefault ''
    \e[1;31m« Welcome to \n @ RNL »\e[0m

    System: \e[0;37m\s \m \r \e[0m
    Users: \e[1;35m\U\e[0m

    IPv4: \e[1;34m\4\e[0m
    IPv6: \e[1;34m\6\e[0m


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
      PermitRootLogin = "without-password";
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
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Configure users
  users.mutableUsers = false; # Disable manual user management
  users.users.root = {
    description = lib.mkForce "Root user to be used by RNL admins";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps @torvalds"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHQiRYpOfTpddexkndt7d3Bw2wS/wLKKjs4526pJOdM @doppler"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBe+xU3BXFYFVoKNAFXG/amC0fhua6S5eK2g6Y+MkwYu @aurelius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7tve12K34nhNgVYZ6VgQBRrJs10v+hClpyzpXTIb/n @raijin"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsoczTbGY6mg9+Ti7LzMMkLvRriMjn1fbD4fTbS2VpR @thor"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDU8SWaX5q+dS5bnWs4ocYORUaMpYVMAGck/rbm3lRif @raidou"
    ];
  };

  # Configure email
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      from = "%U@%C";
    };
    accounts = {
      "default" = {
        host = config.rnl.mailserver.host;
        port = config.rnl.mailserver.port;
        tls = "off";
        tls_starttls = "off";
      };
    };
  };

  # Add certificates
  security.pki.certificateFiles = ["${RNLCert}"];

  # Disable sudo by default because it's not needed
  security.sudo.enable = false;

  # Configure node exporter
  services.prometheus.exporters.node = {
    enable = lib.mkDefault true;
    openFirewall = true; # Open port 9100 (TCP)
  };

  programs.ssh.knownHosts = {
    gitlab-rnl-ed25519 = {
      hostNames = ["gitlab.rnl.tecnico.ulisboa.pt"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGaP0hqVNDA7CPiPC4zd75JKaNpR2kefJ7qmVEiPtCK";
    };
  };

  rnl.githook.emailDestination = "robots@${config.rnl.domain}";

  # Configure bootloader
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    editor = false;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  rnl.labels.core = lib.mkDefault "rnl";
}
