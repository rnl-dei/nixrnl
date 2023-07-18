{
  lib,
  pkgs,
  profiles,
  inputs,
  ...
}: let
  inherit (lib.rnl) rakeLeaves;

  mkPkgs = overlays: let
    args = {
      system = "x86_64-linux"; # FIXME: Allow other systems
      config.allowUnfree = true;
    };
  in
    import inputs.nixpkgs ({
        overlays =
          [
            (self: super: {
              unstable = import inputs.unstable args;
            })
          ]
          ++ lib.attrValues overlays;
      }
      // args);

  mkOverlays = overlaysDir:
    builtins.listToAttrs (map
      (module: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf module);
        value = import module;
      })
      (lib.rnl.listModulesRecursive overlaysDir));

  mkProfiles = profilesDir: rakeLeaves profilesDir;

  mkHost = name: {
    system,
    pkgs,
    profiles,
    hostPath,
    ...
  }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {inherit profiles inputs;};
      modules = [{networking.hostName = name;} hostPath] ++ lib.rnl.listModulesRecursive ../modules;
    };

  mkHosts = hostsDir:
    lib.mapAttrs
    (name: config: mkHost name config)
    (lib.mapAttrs' (name: type: let
        defaultConfig = {
          inherit pkgs profiles inputs;
          hostPath = "${hostsDir}/${name}";
          system = "x86_64-linux";
        };
        extraConfig = lib.mkIf (type == "directoy" && builtins.pathExists "${hostsDir}/${name}/configuration.nix") {
          imports = ["${hostsDir}/${name}/configuration.nix"];
        };
      in {
        name = lib.removeSuffix ".nix" name;
        value = defaultConfig // extraConfig;
      })
      (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)) (builtins.readDir hostsDir)));
in {
  inherit mkProfiles mkHosts mkPkgs mkOverlays;
}
