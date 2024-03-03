{lib, ...}: let
  # Only import the files that end with .json
  listDashboardFiles = path:
    lib.filterAttrs (
      name: type:
        lib.hasSuffix ".json" name && type == "regular"
    ) (builtins.readDir path);

  dashboards = lib.mapAttrs' (name: _: {
    name = lib.removeSuffix ".json" name;
    value = lib.fileset.toSource {
      root = ./dashboards;
      fileset = ./dashboards + "/${name}";
    };
  }) (listDashboardFiles ./dashboards);
in
  dashboards
