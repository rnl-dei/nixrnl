{ inputs, pkgs, ... }:
{
  nix = {
    # Improve nix store disk usage
    gc = {
      automatic = true;
      randomizedDelaySec = "30min";
      dates = "03:15";
      options = "--delete-older-than 7d";
    };

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      unstable.flake = inputs.unstable;
    };

    # Set flake inputs as NIX_PATH channels.
    # This allows nix-shell to work as if a channel exists with the exact copy of nixpkgs
    # (or unstable) that is provided as a flake input. Without it, a user must somehow create
    # channels or set NIX_PATH themselves to use legacy nix commands.
    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "unstable=${inputs.unstable.outPath}"

      # This entry exists in the original NIX_PATH but makes no sense in our machines,
      # as /etc/nixos/configuration.nix does not even exist.
      # "nixos-configuration=/etc/nixos/configuration.nix"

      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    # Generally useful nix option defaults
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      fallback = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # Show diff of updates
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
    '';
  };

  # Setup storage
  rnl.storage.enable = true;

  # Open firewall to keepalived by default
  services.keepalived.openFirewall = true;

  # Set the system configuration revision to the current git revision
  # If the repository is dirty, set it to "dirty"
  # This is useful for tracking which version of the configuration is deployed
  # How to check the system configuration revision: `nixos-version --configuration-revision`
  system.configurationRevision = inputs.self.rev or "dirty";

  system.stateVersion = "23.05";
  rnl.labels.os = "nixos";
}
