{
  config,
  profiles,
  pkgs,
  lib,
  ...
}:
with lib;
let
  users = [
    # each person has its initials as the user
    { username = "vasco.morais"; }
    {
      username = "vicente.araujo";
      shell = pkgs.nushell;
    }
    { username = "vasco.petinga"; }
    { username = "rodrigo.santos"; }
    { username = "simao.lavos"; }
    { username = "tomas.lopes"; }
  ];

  mkThonkUser =
    {
      username,
      shell ? pkgs.bash,
    }:
    {
      users.users.${username} = {
        inherit shell;
        isNormalUser = true;
        description = username;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };
    };
in
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.generic
  ];
}
// mkMerge [
  {
    # Check vault
    users.users.root.hashedPassword = "$y$j9T$kJ9Z/sW6fGpeKy0XUU8lz0$nDMWYA1gO4syvIXjTJ3USXGaoqFpBr2dLWMiVFR1v36";

    # It won't get wifi unless I use this specific option for some reason
    hardware.enableAllFirmware = true;

    # Resolved is used in nixrnl/modules/rnl/wireguard-client.nix
    services.resolved.enable = true;

    # This way each person can set its own password without having to set it here
    users.mutableUsers = mkForce true;

    rnl.storage.disks.root = [
      "/dev/nvme0n1"
    ];

    rnl.labels.location = "Administração RNL";

    # Wireguard configuration
    age.secrets."thonkpad-vpn-keyfile" = {
      file = ../secrets/thonkpad-vpn-key.age;
      owner = "root";
      mode = "600";
    };
    rnl.wireguard-client = {
      enable = true;
      privateKeyFile = config.age.secrets."thonkpad-vpn-keyfile".path;
      lastOctet = 97;
    };
    # /end Wireguard configuration

    # QOL
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

    environment.systemPackages = with pkgs; [
      screen
      vscode.fhs
      mattermost-desktop
      virt-manager
    ];

    virtualisation.libvirtd.enable = true;

    networking.networkmanager.enable = true;

    # So that a user with the nushell shell appears in lighdm
    environment.shells = [ pkgs.nushell ];

    services.xserver = {
      enable = true;
      displayManager.lightdm = {
        enable = true;
        background = config.rnl.wallpaper.path;
      };
      desktopManager.cinnamon = {
        enable = true;

        extraGSettingsOverrides = ''
          # Change default background
          [org.cinnamon.desktop.background]
          picture-uri='file://${config.rnl.wallpaper.path}'

          [org.cinnamon]
          favorite-apps=['firefox.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop', 'code.desktop']
          enabled-applets=['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:separator@cinnamon.org:1', 'panel1:left:2:grouped-window-list@cinnamon.org:2', 'panel1:right:0:systray@cinnamon.org:3', 'panel1:right:1:xapp-status@cinnamon.org:4', 'panel1:right:2:notifications@cinnamon.org:5', 'panel1:right:4:removable-drives@cinnamon.org:7', 'panel1:right:5:keyboard@cinnamon.org:8', 'panel1:right:8:sound@cinnamon.org:11', 'panel1:right:10:calendar@cinnamon.org:13', 'panel1:right:11:cornerbar@cinnamon.org:14']

          [org.cinnamon.theme]
          name='Mint-Y-Dark-Aqua'

          [org.cinnamon.desktop.interface]
          cursor-theme='Adwaita'
          gtk-theme='Mint-Y-Dark-Aqua'
          icon-theme='Mint-Y-Dark-Aqua'

          [org.nemo.desktop]
          home-icon-visible=true
          trash-icon-visible=true
        '';
      };
    };

    # This is likely not needed, but it doesn't hurt either?
    networking.networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
    ];
  }
  (mkMerge (map mkThonkUser users))
]
