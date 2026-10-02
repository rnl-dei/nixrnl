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
    { username = "vm"; }
    {
      username = "va";
      shell = pkgs.nushell;
    }
    { username = "vp"; }
    { username = "rs"; }
    { username = "sl"; }
    { username = "tl"; }
  ];

  mkThonkUser =
    {
      username,
      shell ? pkgs.bash,
    }:
    {
      age.secrets."thonk-initial-root-password.hash" = {
        file = ../secrets/thonk-root-password.hash;
        owner = "root";
      };

      users.users.${username} = {
        inherit shell;
        isNormalUser = true;
        description = username;
        hashedPasswordFile = config.age.secrets."thonk-initial-root-password.hash".path;
      };
    };
in
{
  imports = with profiles; [
    core.rnl
    filesystems.uefi-btrfs-swap
    os.nixos
    type.generic
  ];
}
// mkMerge [
  {
    rnl.storage.disks.root = [
      "/dev/nvme0n1"
    ];

    rnl.labels.location = "Administração RNL";

    rnl.wireguard-client = {
      enable = true;
      privateKeyFile = "/run/TODO";
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

    environment.systemPackages = with pkgs; [
      screen
      vscode.fhs
      mattermost-desktop
      virt-manager
    ];

    virtualisation.libvirtd.enable = true;

    services.xserver.displayManager.gdm.enable = true;

    services.xserver.desktopManager.cinnamon.enable = true;

    networking.networkmanager.plugins = with pkgs; [
      networkmanager-openvpn
    ];
  }
  (mkMerge (map mkThonkUser users))
]
