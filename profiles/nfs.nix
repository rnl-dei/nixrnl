{
  config,
  lib,
  pkgs,
  ...
}:
{
  #TODO add ceph.secret
  fileSystems."/mnt/data/cirrus" = {
    device = "admin@.cirrus_data=/";
    fsType = "ceph";
    options = [
      "mon_addr=193.136.164.113:6789"
      "name=admin"
      "secretfile=/etc/nixos/ceph.secret"
      "_netdev"
    ];
  };

  #NFS Server
  services.nfs.server = {
    enable = true;
    exports = ''
          /mnt/data/cirrus 193.136.164.138(rw,async,no_subtree_check,no_root_squash)
          /mnt/data/cirrus 2001:690:2100:83::138(rw,async,no_subtree_check,no_root_squash)
          /mnt/data/cirrus 193.136.154.0/25(rw,async,no_subtree_check,no_root_squash)
          /mnt/data/cirrus 2001:690:2100:84::/64(rw,async,no_subtree_check,no_root_squash)
        '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.enp1s0.accept_ra" = 1;
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data/cirrus/users 0775 nobody nogroup -"
  ];
}
