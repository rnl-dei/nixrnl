{
  inputs,
  pkgs,
  ...
}: {
  nix = {
    # Improve nix store disk usage
    gc = {
      automatic = true;
      randomizedDelaySec = "30min";
      dates = "03:15";
    };

    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      unstable.flake = inputs.unstable;
    };

    # Generally useful nix option defaults
    settings = {
      keep-outputs = true;
      keep-derivations = true;
      fallback = true;
      experimental-features = ["nix-command" "flakes"];
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

  system.stateVersion = "23.05";
  rnl.labels.os = "nixos";
}
