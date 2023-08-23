{
  lib,
  config,
  ...
} @ args:
with lib; let
  cfg = config.rnl.storage;

  configs = {
    zfs-raid6 = import ./disko/zfs-raid6.nix args;
    simple-uefi = import ./disko/simple-uefi.nix args;
    labs = import ./disko/labs.nix args;
  };
in {
  options.rnl.storage = {
    enable = mkEnableOption "RNL Storage with disko and zfs";
    layout = mkOption {
      type = types.enum ["zfs-raid6" "simple-uefi" "labs"];
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

    disko.devices = configs.${cfg.layout};
  };
}
