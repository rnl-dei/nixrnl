{
  description = "NixOS @ RNL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    unstable,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    profiles = {
      core = {
        rnl = ./profiles/core/rnl.nix;
        dei = ./profiles/core/dei.nix;
      };
    };
  in {
    nixosConfigurations = {
      live = lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          profiles.core.rnl
        ];
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
