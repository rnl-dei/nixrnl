{
  pkgs,
  lib,
  config,
  ...
}:
let
  listenPort = 34266;

  outInterface = config.networking.nat.externalInterface;
  hosts = import ./hosts.nix;

  # Allowed IPs will look like this:
  # 192.168.20.<lastOctet> fd92:3315:9e43:c490::<lastOctet>/128 (plus extra ips for multicast)
  mkPeers = builtins.map (peer: {
    inherit (peer) publicKey;
    allowedIPs = [
      "192.168.20.${toString peer.lastOctet}/32"
      "fd92:3315:9e43:c490::${toString peer.lastOctet}/128"
      "224.0.0.0/24"
      "ff00::/16"
    ];
  });
in
{
  networking.nat.enable = true;
  assertions = [
    {
      assertion = config.networking.nat.externalInterface != null;
      message = "networking.nat.externalInterface must be set";
    }
  ];
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ listenPort ];
  };

  age.secrets."wireguard-admin-private.key" = {
    file = ../../../secrets/wireguard-admin-private-key.age;
    mode = "0400";
    owner = "root";
  };

  networking.wireguard.interfaces = {
    wg0 = {
      inherit listenPort;
      privateKeyFile = config.age.secrets."wireguard-admin-private.key".path;
      ips = [ "192.168.20.254/24" ];
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.20.0/24 -o ${outInterface} -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.20.0/24 -o ${outInterface} -j MASQUERADE
      '';

      peers = mkPeers hosts;
    };
  };

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.wireguardAdminIP4 = {
      virtualRouterId = 211;
      interface = outInterface;
      virtualIps = [ { addr = "193.136.164.211/27"; } ]; # fang IPv4
    };
    vrrpInstances.wireguardAdminIP6 = {
      virtualRouterId = 211;
      interface = outInterface;
      virtualIps = [ { addr = "2001:690:2100:82::211/64"; } ]; # fang IPv6
    };
  };

  # Configure wireguard exporter
  services.prometheus.exporters.wireguard = {
    enable = lib.mkDefault true;
    openFirewall = true;
    withRemoteIp = lib.mkForce false; # Don't track remote IPs
  };
}
