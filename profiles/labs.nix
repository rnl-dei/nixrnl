{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Required for command-not-found to work using flakes
    inputs.flake-programs-sqlite.nixosModules.programs-sqlite
    ./ist/shell.nix
    ./pull.nix
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
  systemd.tmpfiles.rules = [
    "f+  /etc/subuid 0644 root root -"
    "f+  /etc/subgid 0644 root root -"
  ];

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

  # Enable Wake on Lan
  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.wakeOnLan.enable = true;

  # Disable firewall, to simplify everyone's life
  networking.firewall.enable = lib.mkForce false;

  age.secrets."netrc" = {
    file = ../secrets/open-sessions-key.age;
    mode = "0400";
    path = "/etc/open-sessions/netrc";
  };

  # RNL Virt / Reboot2
  environment.systemPackages = with pkgs; [
    rnl-virt
    reboot2
  ];
  virtualisation.libvirtd.enable = true;

  # Extra users
  users.users = {
    # welcome = {
    #   isNormalUser = true;
    #   description = "Welcome user for the RNL";
    #   password = "welcome";
    #   extraGroups = ["volatile" "no-ssh"];
    # };
  };

  users.groups = {
    no-ssh = { }; # Group for users that should not have SSH access
    volatile = { }; # Group for volatile home directories
  };

  services.openssh.settings.DenyGroups = [ config.users.groups.no-ssh.name ];
  security.pam.mount = {
    enable = true;
    extraVolumes = [
      # Volatile home directories
      "<volume sgrp=\"${config.users.groups.volatile.name}\" fstype=\"tmpfs\" mountpoint=\"/home/%(USER)\" options=\"size=2048M,uid=%(USERUID),gid=%(USERGID),mode=0700\" />"
    ];
  };

  # Open Sessions
  systemd.services."sessioncontrol" = {
    description = "RNL session control";
    requires = [ "network-online.target" ];
    after = [
      "network.target"
      "network-online.target"
    ];
    serviceConfig = {
      Type = "simple";
      RemainAfterExit = true;
      ExecStart = "${pkgs.opensessions-scripts}/bin/session-control.sh boot";
      ExecStop = "${pkgs.opensessions-scripts}/bin/session-control.sh shutdown";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Add after run ist-shell scripts
  security.pam.services.login.text = lib.mkIf (config.systemd.services."sessioncontrol".enable) (
    lib.mkDefault (
      lib.mkOrder 2000 ''
        session optional pam_exec.so ${pkgs.opensessions-scripts}/bin/session-control.sh
      ''
    )
  );
  security.pam.services.sshd.text = lib.mkIf (config.systemd.services."sessioncontrol".enable) (
    lib.mkDefault (
      lib.mkOrder 2000 ''
        session optional pam_exec.so ${pkgs.opensessions-scripts}/bin/session-control.sh
      ''
    )
  );

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
