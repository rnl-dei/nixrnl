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

    secretAgeFile = mkOption {
      type = types.path;
      description = "Path to secrets";
    };
  };

  config = mkIf cfg.enable {

    age.secrets.ceph_secret = {
      file = cfg.secretAgeFile;
      owner = "root";
    };

    fileSystems."/mnt/data/cirrus" = {
      device = "admin@.cephfs=/";
      fsType = "ceph";
      options = [
        "mon_addr=${cfg.host}:3300"
        "name=admin"
        "secretfile=${config.age.secrets.ceph_secret.path}"
        "_netdev"
      ];
    };
  };
}
