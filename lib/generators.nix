{
  lib,
  pkgs,
  profiles,
  inputs,
  nixosConfigurations,
  ...
} @ args: let
  inherit (lib.rnl) rakeLeaves;

  mkPkgs = overlays: let
    argsPkgs = {
      system = "x86_64-linux"; # FIXME: Allow other systems
      config.allowUnfree = true;
    };
  in
    import inputs.nixpkgs ({
        overlays =
          [
            (self: super: {
              unstable = import inputs.unstable argsPkgs;
            })
          ]
          ++ lib.attrValues overlays;
      }
      // argsPkgs);

  mkOverlays = overlaysDir:
    builtins.listToAttrs (map
      (module: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf module);
        value = import module;
      })
      (lib.rnl.listModulesRecursive overlaysDir));

  mkProfiles = profilesDir: rakeLeaves profilesDir;

  mkHost = {
    system,
    hostname,
    hostPath,
    extraModules ? [],
    ...
  }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {inherit profiles inputs nixosConfigurations;};
      modules = [{networking.hostName = hostname;} hostPath] ++ extraModules ++ lib.rnl.listModulesRecursive ../modules;
    };

  mkHosts = hostsDir:
    lib.listToAttrs (lib.lists.flatten (lib.mapAttrsToList (name: type: let
      hostPath = hostsDir + "/${name}";
      configPath = hostPath + "/configuration.nix";
      hostname = lib.removeSuffix ".nix" (builtins.baseNameOf hostPath);
      cfg =
        {
          inherit hostPath pkgs profiles inputs;
          system = "x86_64-linux";
          aliases = [
            {
              inherit hostname;
              extraModules = [];
            }
          ];
        }
        // (lib.optionalAttrs (type == "directory" && builtins.pathExists configPath) (import configPath args));
      aliases' = cfg.aliases;
      cfg' = lib.filterAttrs (name: value: name != "aliases") cfg;
      aliases = builtins.map (alias: alias // cfg') aliases';
    in (builtins.map (alias: {
        name = alias.hostname;
        value = mkHost alias;
      })
      aliases)) (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)) (builtins.readDir hostsDir))));

  mkLabs = lab: num: builtins.map (x: "${lab}p${toString x}") (lib.range 1 num);

in {
  inherit mkProfiles mkHosts mkPkgs mkOverlays mkLabs;
}
