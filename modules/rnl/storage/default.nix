{
  lib,
  config,
  ...
} @ args:
with lib; let
  cfg = config.rnl.storage;

  configs = lib.mapAttrsToList (n: _: lib.removeSuffix ".nix" n) (builtins.readDir ./disko);
in {
  options.rnl.storage = {
    enable = mkEnableOption "RNL Storage with disko";
    layout = mkOption {
      type = types.enum configs;
      description = "Storage type";
    };
    disks = {
      root = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Root disk";
      };
      data = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Data disk";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.disks.root != [];
        message = "Host ${config.networking.hostName} has no root disk";
      }
    ];

    disko.devices = import (./disko + "/${cfg.layout}.nix") args;
  };
}
