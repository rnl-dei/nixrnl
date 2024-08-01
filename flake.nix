{
  description = "NixOS @ RNL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Comment out because it's not used
    # rnl-config.url = "git+ssh://git@gitlab.rnl.tecnico.ulisboa.pt/rnl/nixos-private-config";
    # rnl-config.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS Anywhere used by dev shell to deploy to remote machines
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.nixos-stable.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";
    nixos-anywhere.inputs.treefmt-nix.follows = "treefmt-nix";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.systems.follows = "systems";

    # Required for command-not-found
    flake-programs-sqlite.url = "github:wamserma/flake-programs-sqlite";
    flake-programs-sqlite.inputs.nixpkgs.follows = "nixpkgs";
    flake-programs-sqlite.inputs.utils.follows = "flake-utils";

    # IST Delegate Election
    ist-delegate-election.url = "github:diogotcorreia/ist-delegate-election";
    ist-delegate-election.inputs.nixpkgs.follows = "nixpkgs";

    # Wolbridge
    wolbridge.url = "git+https://gitlab.rnl.tecnico.ulisboa.pt/rnl/infra/wolbridge";
    wolbridge.inputs.nixpkgs.follows = "nixpkgs";
    wolbridge.inputs.poetry2nix.follows = "poetry2nix";

    ist-delegate-election.inputs.flake-utils.follows = "flake-utils";

    # We only have these inputs to pass to other dependencies and
    # avoid having multiple versions in our flake.
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    systems.url = "github:nix-systems/default";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.flake-utils.follows = "flake-utils";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.inputs.systems.follows = "systems";
    poetry2nix.inputs.treefmt-nix.follows = "treefmt-nix";
  };

  outputs = {
    nixpkgs,
    unstable,
    ...
  } @ inputs: let
    lib = nixpkgs.lib.extend (self: super:
      import ./lib {
        inherit inputs profiles pkgs nixosConfigurations;
        lib = self;
      });

    overlays = lib.rnl.mkOverlays ./overlays;
    pkgs = lib.rnl.mkPkgs overlays;
    nixosConfigurations = lib.rnl.mkHosts ./hosts;
    profiles = lib.rnl.mkProfiles ./profiles;
  in {
    inherit nixosConfigurations overlays;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        inputs.agenix.packages.x86_64-linux.agenix
        deploy-anywhere # Customized version of nixos-anywhere with Hashicorp Vault
        secrets-check
      ];
    };

    packages.x86_64-linux = {
      deploy-anywhere = pkgs.deploy-anywhere;
      secrets-check = pkgs.secrets-check;
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
