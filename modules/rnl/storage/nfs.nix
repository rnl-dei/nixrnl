{ config, lib, ... }:
with lib;
let
  cfg = config.rnl.nfs;
in
{
  options.rnl.nfs = {
    enable = mkEnableOption {
      default = false;
    };
    host = mkOption {
      type = types.ip-address;
      description = "Ceph machine";
      default = 193.136 .164 .113;
    };

  };

  config = mkIf cfg.enable {

  };
}
