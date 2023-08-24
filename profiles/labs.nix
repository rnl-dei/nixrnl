{
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

  # Enable DHCP
  networking.useDHCP = lib.mkForce true;
  networking.dhcpcd.extraConfig = ''
    duid ll   # Allow DHCP server to assign a static IPv6 using the MAC address
  '';

  # RNL Virt
  environment.systemPackages = with pkgs; [rnl-virt];
  virtualisation.libvirtd.enable = true;

  # Bootloader
  boot = {
    plymouth.enable = true;

    loader = {
      efi.canTouchEfiVariables = lib.mkForce true;
      # TODO custom entries; root and password; lock entries
      grub = {
        efiInstallAsRemovable = false;
        configurationName = "Linux";
        configurationLimit = 1;
      };
    };
  };
}
