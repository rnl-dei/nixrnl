{
  description = "NixOS @ RNL";

  nixConfig = {
    extra-substituters = [ "https://proxy.cache.rnl.tecnico.ulisboa.pt?priority=38" ];
    extra-trusted-public-keys = [
      "proxy.cache.rnl.tecnico.ulisboa.pt:nqg28rqC5jNdevtd7DLIpvUPDBmv2D8hhWy0REBh5lU="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Comment out because it's not used
    # rnl-config.url = "git+ssh://git@gitlab.rnl.tecnico.ulisboa.pt/rnl/nixos-private-config";
    # rnl-config.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS Anywhere used by dev shell to deploy to remote machines
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-anywhere.inputs.nixos-stable.follows = "nixpkgs";
    nixos-anywhere.inputs.disko.follows = "disko";
    nixos-anywhere.inputs.treefmt-nix.follows = "treefmt-nix";
    nixos-anywhere.inputs.flake-parts.follows = "flake-parts";

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
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.inputs.nixpkgs-stable.follows = "nixpkgs";

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
      git-hooks,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib.extend (
        self: _super:
        import ./lib {
          inherit inputs profiles nixosConfigurations;
          lib = self;
        }
      );

      overlays = lib.rnl.mkOverlays ./overlays;
      nixosConfigurations = lib.rnl.mkHosts overlays ./hosts;
      profiles = lib.rnl.mkProfiles ./profiles;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks.flakeModule ];

      systems = [
        # list of systems for which the `perSystem` attributes will be built.
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        # Expose self and lib so they can be used with `nix repl`.
        # This is non-standard, but nixpkgs does this as well.
        inherit self lib;
        inherit nixosConfigurations overlays;
      };

      # list of useful attributes, for reference:
      # perSystem = { config, self', inputs', pkgs, system, ... }: {
      debug = true;
      perSystem =
        {
          config,
          pkgs,
          inputs',
          system,
          ...
        }:
        let
          rnlPkgs = (lib.rnl.rnlPkgs) pkgs;
        in

        {
          _module.args.debug = true;
          _module.args.pkgs = lib.rnl.mkPkgs system outputs.overlays;

          devShells.default = pkgs.mkShell {
            packages =
              config.pre-commit.settings.enabledPackages
              ++ (with rnlPkgs; [
                inputs'.agenix.packages.agenix
                deploy-anywhere # Customized version of nixos-anywhere with Hashicorp Vault
                secrets-check
              ]);
            shellHook = ''
              # export DEBUG=1
              ${config.pre-commit.installationScript}
            '';
          };

          legacyPackages = rnlPkgs;

          pre-commit.settings.hooks = {
            # Nix
            deadnix.enable = true;
            # TODO: consider enabling
            # statix.enable = true;
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
            #TODO: consider adding git commit e-mail check as pre-commit-hook
          };
        };
    };
}
