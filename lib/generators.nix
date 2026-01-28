{
  lib,
  pkgs,
  profiles,
  inputs,
  nixosConfigurations,
  ...
}@args:
let
  inherit (lib.rnl) rakeLeaves;

  /*
    *
    Synopsis: mkPkgs overlays

    Generate an attribute set representing Nix packages with custom overlays.

    Inputs:
    - overlays: An attribute set of overlays to apply on top of the main Nixpkgs.

    Output Format:
    An attribute set representing Nix packages with custom overlays applied.
    The function imports the main Nixpkgs and applies additional overlays defined in the `overlays` argument.
    It then merges the overlays with the provided `argsPkgs` attribute set.

    *
  */
  mkPkgs =
    overlays:
    let
      argsPkgs = {
        system = "x86_64-linux"; # FIXME: Allow other systems
        config.allowUnfree = true;
        # DEI - PHDMS
        config.permittedInsecurePackages = [
          "python3.12-django-3.2.25"
          "python3.11-django-3.2.25"
        ];
      };
    in
    import inputs.nixpkgs (
      {
        overlays = [
          (_self: _super: {
            unstable = import inputs.unstable argsPkgs;
            allowOpenSSL = import inputs.nixpkgs (
              argsPkgs // { config.permittedInsecurePackages = [ "openssl-1.1.1w" ]; }
            );
            allowSquid = import inputs.nixpkgs (
              argsPkgs // { config.permittedInsecurePackages = [ "squid-5.9" ]; }
            );
          })
        ]
        ++ lib.attrValues overlays;
      }
      // argsPkgs
    );

  /*
    *
    Synopsis: mkOverlays overlaysDir

    Generate overlays for Nix expressions found in the specified directory.

    Inputs:
    - overlaysDir: The path to the directory containing Nix expressions.

    Output Format:
    An attribute set representing Nix overlays.
    The function recursively scans the `overlaysDir` directory for Nix expressions and imports each overlay.

    *
  */
  mkOverlays =
    overlaysDir:
    lib.mapAttrsRecursive (_: module: import module { inherit rakeLeaves inputs; }) (
      lib.rnl.rakeLeaves overlaysDir
    );

  /*
    *
    Synopsis: mkProfiles profilesDir

    Generate profiles from the Nix expressions found in the specified directory.

    Inputs:
    - profilesDir: The path to the directory containing Nix expressions.

    Output Format:
    An attribute set representing profiles.
    The function uses the `rakeLeaves` function to recursively collect Nix files
    and directories within the `profilesDir` directory.
    The result is an attribute set mapping Nix files and directories
    to their corresponding keys.

    *
  */

  mkProfiles = profilesDir: rakeLeaves profilesDir;
  /*
    *
    Synopsis: mkHyper hostname  { system, hostPath, extraModules ? [] }

    Generate a system-manager system configuration for the specified hostname, made for hypervisors.

    Inputs:
    - hostname: The hostname for the target OpenSuse system.
    - system: The target system platform (e.g., "x86_64-linux").
    - hostPath: The path to the directory containing host-specific Nix configurations.
    - extraModules: An optional list of additional NixOS modules to include in the configuration.

    Output Format:
    A systemConfigs system configuration representing the specified hostname. The function generates a SystemManager system configuration using the provided parameters and additional modules. It inherits attributes from `pkgs`, `lib`, `profiles`, `inputs`, `systemConfigs`, and other custom modules.

    *
  */
  mkHyper =
    {
      hostPath,
      extraModules ? [ ],
      ...
    }:
    inputs.system-manager.lib.makeSystemConfig {
      modules =
        (lib.collect builtins.isPath (lib.rnl.rakeLeaves ../modules))
        ++ [
          hostPath
        ]
        ++ extraModules;
    };
  /*
    *
    Synopsis: mkHypers hostsDir

    Generate a set of SystemManager system configurations for the hosts defined in the specified directory.

    Inputs:
    - hostsDir: The path to the directory containing host-specific configurations.

    Output Format:
    An attribute set representing SystemManager system configurations for the hosts
    found in the `hostsDir`. The function scans the `hostsDir` directory
    for host-specific Nix configurations and generates a set of SystemManager
    system configurations for each host. The resulting attribute set maps
    hostnames to their corresponding SystemManager system configurations.
    *
  */
  mkHypers =
    hostsDir:
    lib.listToAttrs (
      lib.lists.flatten (
        lib.mapAttrsToList
          (
            name: type:
            let
              # Get hostname from host path
              hostPath = hostsDir + "/${name}";
              configPath = hostPath + "/configuration.nix";
              hostname = lib.removeSuffix ".nix" (builtins.baseNameOf hostPath);

              # Merge default configuration with host configuration (if it exists)
              cfg = {
                inherit
                  hostPath
                  pkgs
                  profiles
                  inputs
                  ;
                aliases = null;
              }
              // hostCfg;

              hostCfg = lib.optionalAttrs (type == "directory" && builtins.pathExists configPath) (
                import configPath args
              );

              # Remove aliases from host configuration
              # and merge aliases with hosts
              aliases' =
                if (cfg.aliases != null) then
                  cfg.aliases
                else
                  {
                    ${hostname} = {
                      extraModules = [ ];
                    };
                  };
              cfg' = lib.filterAttrs (name: _: name != "aliases") cfg;
              aliases = lib.mapAttrs (_: value: (value // cfg')) aliases';
            in
            (lib.mapAttrsToList (hostname: {
              name = hostname;
              value = mkHyper;
            }) aliases)
          )
          # Ignore hosts starting with an underscore
          (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)) (builtins.readDir hostsDir))
      )
    );
  /*
    *
    Synopsis: mkHost hostname  { system, hostPath, extraModules ? [] }

    Generate a NixOS system configuration for the specified hostname.

    Inputs:
    - hostname: The hostname for the target NixOS system.
    - system: The target system platform (e.g., "x86_64-linux").
    - hostPath: The path to the directory containing host-specific Nix configurations.
    - extraModules: An optional list of additional NixOS modules to include in the configuration.

    Output Format:
    A NixOS system configuration representing the specified hostname. The function generates a NixOS system configuration using the provided parameters and additional modules. It inherits attributes from `pkgs`, `lib`, `profiles`, `inputs`, `nixosConfigurations`, and other custom modules.

    *
  */

  mkHost =
    hostname:
    {
      system,
      hostPath,
      extraModules ? [ ],
      ...
    }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {
        inherit profiles inputs nixosConfigurations;
      };
      modules =
        (lib.collect builtins.isPath (lib.rnl.rakeLeaves ../modules))
        ++ [
          { networking.hostName = hostname; }
          hostPath
          #inputs.rnl-config.nixosModules.rnl
          inputs.disko.nixosModules.disko
          inputs.agenix.nixosModules.age
        ]
        ++ extraModules;
    };

  /*
    *
    Synopsis: mkHosts hostsDir

    Generate a set of NixOS system configurations for the hosts defined in the specified directory.

    Inputs:
    - hostsDir: The path to the directory containing host-specific configurations.

    Output Format:
    An attribute set representing NixOS system configurations for the hosts
    found in the `hostsDir`. The function scans the `hostsDir` directory
    for host-specific Nix configurations and generates a set of NixOS
    system configurations for each host. The resulting attribute set maps
    hostnames to their corresponding NixOS system configurations.
    *
  */
  mkHosts =
    hostsDir:
    lib.listToAttrs (
      lib.lists.flatten (
        lib.mapAttrsToList
          (
            name: type:
            let
              # Get hostname from host path
              hostPath = hostsDir + "/${name}";
              configPath = hostPath + "/configuration.nix";
              hostname = lib.removeSuffix ".nix" (builtins.baseNameOf hostPath);

              # Merge default configuration with host configuration (if it exists)
              cfg = {
                inherit
                  hostPath
                  pkgs
                  profiles
                  inputs
                  ;
                system = "x86_64-linux";
                aliases = null;
              }
              // hostCfg;

              hostCfg = lib.optionalAttrs (type == "directory" && builtins.pathExists configPath) (
                import configPath args
              );

              # Remove aliases from host configuration
              # and merge aliases with hosts
              aliases' =
                if (cfg.aliases != null) then
                  cfg.aliases
                else
                  {
                    ${hostname} = {
                      extraModules = [ ];
                    };
                  };
              cfg' = lib.filterAttrs (name: _: name != "aliases") cfg;
              aliases = lib.mapAttrs (_: value: (value // cfg')) aliases';
            in
            (lib.mapAttrsToList (hostname: alias: {
              name = hostname;
              value = mkHost hostname alias;
            }) aliases)
          )
          # Ignore hosts starting with an underscore
          (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)) (builtins.readDir hostsDir))
      )
    );

  /*
    *
    Synopsis: mkSecrets secretsDir

    Generate a set of secrets to be used by agenix.

    Inputs:
    - secretsDir: The path to the directory containing secrets.

    Output Format:
    An attribute set representing secrets.
    The function scans the `secretsDir` directory recursively for secrets and
    generates a set of secrets for each host.
    The resulting attribute set maps paths to their corresponding secret file.

    Example input:
    ```
    ./secrets/secrets.nix
    ./secrets/key1.age
    ./secrets/key2.nix
    ./secrets/host-keys/key3.age
    ```

    Example output:
    {
     "key1".file = ./secrets/key1.age;
     "key2".file = ./secrets/key2.age;
     "host-keys/key3".file = ./secrets/host-keys/key3.age;
    }
    *
  */
  mkSecrets =
    secretsDir:
    builtins.listToAttrs (
      builtins.map (
        file:
        let
          name = lib.removePrefix (toString secretsDir + "/") (toString file);
        in
        {
          inherit name;
          value = {
            inherit file;
          };
        }
      ) (builtins.filter (p: lib.hasSuffix ".age" p) (lib.filesystem.listFilesRecursive secretsDir))
    );

  /*
    *
    Synopsis: mkLabs lab num

    Generate a set of labs hosts.

    Inputs:
    - lab: The name of the lab.
    - num: The number of hosts in the lab.

    Output Format:
    An attribute set representing the generated labs from labXp1 to labXpN.

    Example input:
    mkLabs "lab1" 3

    Example output:
    {
      lab1p1 = {};
      lab1p2 = {};
      lab1p3 = {};
    }

    *
  */
  mkLabs =
    lab: num:
    builtins.listToAttrs (
      builtins.map (x: {
        name = "${lab}p${toString x}";
        value = { };
      }) (lib.range 1 num)
    );

  /*
    *
    Synopsis: mkStaticConfigs hosts targets extraLabels

    Generate a set of static configurations to prometheus for the specified hosts.

    Inputs:
    - hosts: A set of nixosConfigurations hosts to generate static configurations for.
    - targets: A list of functions that generate a list of targets for a given host config.
    - extraLabels: A list of functions that generate a list of labels for a given host config.

    Output Format:
    A list of attribute sets representing static configurations for the specified hosts.
    Each set contains the `targets` and the respective `labels` for the targets.

    Example input:
    mkStaticConfigs
      { example1 = <nixosConfiguration>; example2 = <nixosConfiguration>; }
      [ (config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}") ]
      []

    Example output:
    [
      {
        targets = [ "example1.example.com:9100" ];
        labels = { location = "inf1"; type = "vm"; };
      }
      {
        targets = [ "example2.example.com:9100" ];
        labels = { type = "hypervisor"; };
      }
    ]

    *
  */
  mkStaticConfigs =
    hosts: targets: extraLabels:
    lib.mapAttrsToList (
      _:
      { config, ... }:
      {
        targets = lib.lists.flatten (builtins.map (target: target config) targets);
        labels =
          (lib.filterAttrs (_: v: v != null) config.rnl.labels)
          // (builtins.listToAttrs (builtins.map (label: label config) extraLabels));
      }
    ) hosts;
in
{
  inherit
    mkProfiles
    mkHypers
    mkHosts
    mkPkgs
    mkOverlays
    mkSecrets
    mkLabs
    mkStaticConfigs
    ;
}
