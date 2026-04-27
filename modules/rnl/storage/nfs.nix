{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rnl.nfs;
in
{
  options.rnl.nfs = {
    enable = mkEnableOption "Enable RNL NFS storage";
    cephHost = mkOption {
      type = types.ip-address;
      description = "Ceph machine containing storage";
      default = "193.136.164.113";
    };
    cephPort = mkOption {
      type = types.int;
      default = 3300;
    };
    cephSecretPath = mkOption {
      type = types.str;
      description = "path containing ceph secret";
    };
    path = mkOption {
      type = types.str;
      description = "Where in the machine the data will be mounted";
      default = "/mnt/data/${config.networking.hostName}";
    };
  };

  config = mkIf cfg.enable {
    # fileSystems.${cfg.path} = {
    #     device = "admin@.cephfs=/";
    #     fsType = "ceph";
    #     options = [
    #       "mon_addr=${cfg.cephHost}:${cfg.cephPort}"
    #       "name=admin"
    #       "secretfile=${cfg.cephSecretPath}"
    #       "secretfile=${config.age.secrets.ceph_secret.path}"
    #       "_netdev"
    #     ];
    #   };
    systemd.tmpfiles.rules = [ "d ${cfg.path}/users 0775 nobody nogroup -" ];
    # services.nfs.server = {
    #   enable = true;
    #   # allow borg and labs to mount cirrus
    #   exports = ''
    #     /mnt/data/cirrus 193.136.164.138(rw,async,no_subtree_check,no_root_squash)
    #     /mnt/data/cirrus 2001:690:2100:83::138(rw,async,no_subtree_check,no_root_squash)
    #     /mnt/data/cirrus 193.136.154.0/25(rw,async,no_subtree_check,no_root_squash)
    #     /mnt/data/cirrus 2001:690:2100:84::/64(rw,async,no_subtree_check,no_root_squash)
    #   '';
    # };
  };
}
