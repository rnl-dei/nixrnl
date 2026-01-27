{
  description = "NixOS @ RNL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Comment out because it's not used
    # rnl-config.url = "git+ssh://git@gitlab.rnl.tecnico.ulisboa.pt/rnl/nixos-private-config";
    # rnl-config.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    #System manager for non NixOS based systems (aka OpenSuse hypervisors)
    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

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

    # Opensessions
    opensessions.url = "git+https://gitlab.rnl.tecnico.ulisboa.pt/rnl/infra/Opensessions2";
    opensessions.inputs.nixpkgs.follows = "nixpkgs";

    # Wolbridge
    wolbridge.url = "git+https://gitlab.rnl.tecnico.ulisboa.pt/rnl/infra/wolbridge";
    wolbridge.inputs.nixpkgs.follows = "nixpkgs";
    wolbridge.inputs.poetry2nix.follows = "poetry2nix";

    ist-delegate-election.inputs.flake-utils.follows = "flake-utils";

    # Runs checks before committing
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

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

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib.extend (
        self: _super:
        import ./lib {
          inherit
            inputs
            profiles
            pkgs
            systemConfigs
            nixosConfigurations
            ;
          lib = self;
        }
      );

      overlays = lib.rnl.mkOverlays ./overlays;
      pkgs = lib.rnl.mkPkgs overlays;
      nixosConfigurations = lib.rnl.mkHosts ./hosts;
      systemConfigs = lib.rnl.mkHypers ./hypervisers;
      profiles = lib.rnl.mkProfiles ./profiles;
    in
    {
      inherit nixosConfigurations systemConfigs overlays;

      devShells.x86_64-linux.default = pkgs.mkShell {
        inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
        buildInputs =
          self.checks.x86_64-linux.pre-commit-check.enabledPackages
          ++ (with pkgs; [
            inputs.agenix.packages.x86_64-linux.agenix
            deploy-anywhere # Customized version of nixos-anywhere with Hashicorp Vault
            secrets-check
          ]);
      };

      packages.x86_64-linux = {
        deploy-anywhere = pkgs.deploy-anywhere;
        secrets-check = pkgs.secrets-check;
      };

      checks.x86_64-linux.pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
        src = ./.;
        hooks = {
          # Nix
          deadnix.enable = true;
          nixfmt-rfc-style.enable = true;

          # Shell
          shellcheck.enable = true;
          shfmt.enable = true;

          # Git
          check-merge-conflicts.enable = true;
          forbid-new-submodules.enable = true;

          # Spellcheck
          typos = {
            enable = true;
            pass_filenames = false; # must configure excludes through typos.toml
            settings.configPath = "./typos.toml";
          };
        };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
