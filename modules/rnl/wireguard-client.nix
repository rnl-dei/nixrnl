{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.rnl.wireguard-client;
in
{
  options.rnl.wireguard-client = {
    enable = mkEnableOption "Enable the wireguard VPN connection as a client";
    privateKeyFile = mkOption {
      type = types.str;
      description = "The private key file to use";
    };
  };

  config = mkIf cfg.enable {
    networking.wg-quick.interfaces.wgrnl =
      let
        wgrnlFwmark = "765";
      in
      {
        inherit (cfg) privateKeyFile;
        address = [
          "192.168.20.X/24"
          "fd92:3315:9e43:c490::X/64"
        ];
        table = wgrnlFwmark;
        postUp = ''
          # Setup routing entre routing tables (aka maravilha do Breda)
          ${pkgs.wireguard-tools}/bin/wg set wgrnl fwmark ${wgrnlFwmark}
          ${pkgs.iproute2}/bin/ip rule add not fwmark ${wgrnlFwmark} table ${wgrnlFwmark}
          ${pkgs.iproute2}/bin/ip -6 rule add not fwmark ${wgrnlFwmark} table ${wgrnlFwmark}

          # multicast
          ${pkgs.iproute2}/bin/ip link set wgrnl multicast on

          # systemd-resolved
          # Adiciona como domínios desta interface todos os domínios (~.).
          # Para o caso de aparecerem outras interfaces com maior prioridade, adiciona também todos os domínios da RNL, e todos os domínios de rDNS para gamas da RNL (públicas, privadas e watergate no INESC). Todos os domínios excepto rnl.tecnico.ulisboa.pt começam com ~ para desligar dns-search neles.
          ${pkgs.systemd}/bin/resolvectl dns wgrnl 193.136.164.1 2001:690:2100:80::1 193.136.164.2 2001:690:2100:80::2
          ${pkgs.systemd}/bin/resolvectl domain wgrnl ~. rnl.tecnico.ulisboa.pt ~rnl.ist.utl.pt ~rnl.pt ~164.136.193.in-addr.arpa ~154.136.193.in-addr.arpa ~8.0.0.0.0.1.2.0.9.6.0.1.0.0.2.ip6.arpa ~81.33.193.146.in-addr.arpa ~20.168.192.in-addr.arpa ~0.9.4.c.3.4.e.9.5.1.3.3.2.9.d.f.ip6.arpa ~154.168.192.in-addr.arpa ~64.16.10.in-addr.arpa ~65.16.10.in-addr.arpa ~66.16.10.in-addr.arpa ~67.16.10.in-addr.arpa ~68.16.10.in-addr.arpa ~69.16.10.in-addr.arpa ~70.16.10.in-addr.arpa ~71.16.10.in-addr.arpa ~72.16.10.in-addr.arpa ~73.16.10.in-addr.arpa ~74.16.10.in-addr.arpa ~75.16.10.in-addr.arpa ~76.16.10.in-addr.arpa ~77.16.10.in-addr.arpa ~78.16.10.in-addr.arpa ~79.16.10.in-addr.arpa ~80.16.10.in-addr.arpa ~81.16.10.in-addr.arpa ~82.16.10.in-addr.arpa ~83.16.10.in-addr.arpa ~84.16.10.in-addr.arpa ~85.16.10.in-addr.arpa ~86.16.10.in-addr.arpa ~87.16.10.in-addr.arpa ~88.16.10.in-addr.arpa ~89.16.10.in-addr.arpa ~90.16.10.in-addr.arpa ~91.16.10.in-addr.arpa ~92.16.10.in-addr.arpa ~93.16.10.in-addr.arpa ~94.16.10.in-addr.arpa ~95.16.10.in-addr.arpa ~96.16.10.in-addr.arpa ~97.16.10.in-addr.arpa ~98.16.10.in-addr.arpa ~99.16.10.in-addr.arpa ~100.16.10.in-addr.arpa ~101.16.10.in-addr.arpa ~102.16.10.in-addr.arpa ~103.16.10.in-addr.arpa ~104.16.10.in-addr.arpa ~105.16.10.in-addr.arpa ~106.16.10.in-addr.arpa ~107.16.10.in-addr.arpa ~108.16.10.in-addr.arpa ~109.16.10.in-addr.arpa ~110.16.10.in-addr.arpa ~111.16.10.in-addr.arpa ~112.16.10.in-addr.arpa ~113.16.10.in-addr.arpa ~114.16.10.in-addr.arpa ~115.16.10.in-addr.arpa ~116.16.10.in-addr.arpa ~117.16.10.in-addr.arpa ~118.16.10.in-addr.arpa ~119.16.10.in-addr.arpa ~120.16.10.in-addr.arpa ~121.16.10.in-addr.arpa ~122.16.10.in-addr.arpa ~123.16.10.in-addr.arpa ~124.16.10.in-addr.arpa ~125.16.10.in-addr.arpa ~126.16.10.in-addr.arpa ~127.16.10.in-addr.arpa
        '';
        preDown = ''
          ${pkgs.iproute2}/bin/ip rule del not fwmark ${wgrnlFwmark} table ${wgrnlFwmark}
          ${pkgs.iproute2}/bin/ip -6 rule del not fwmark ${wgrnlFwmark} table ${wgrnlFwmark}
        '';

        peers = [
          {
            publicKey = "g08PXxMmzC6HA+Jxd+hJU0zJdI6BaQJZMgUrv2FdLBY=";
            endpoint = "193.136.164.216:34266";
            allowedIPs = [
              # gamas públicas da RNL
              "193.136.164.0/24"
              "193.136.154.0/24"
              "2001:690:2100:80::/58"

              # gamas privadas da RNL
              "10.16.64.0/18" # routed dentro do IST
              "192.168.20.0/24" # VPN IPv4
              "fd92:3315:9e43:c490::/64" # VPN IPv6
              "192.168.154.0/24" # Labs AMT

              # gama uplink Zeus (DSI+RNL)
              "193.136.128.24/29"

              # watergate (INESC)
              "146.193.33.81/32"

              # multicast e mDNS
              "224.0.0.0/24"
              "ff02::/16"
              "239.255.255.250/32"
              "239.255.255.253/32"
              "fe80::/10"
            ];
            persistentKeepalive = 25;
          }
        ];
      };

    networking.firewall =
      let
        port = "34266";
      in
      {
        # if packets are still dropped, they will show up in dmesg
        logReversePathDrops = true;
        # wireguard trips rpfilter up
        extraCommands = ''
          ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport ${port} -j RETURN
          ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport ${port} -j RETURN
        '';
        extraStopCommands = ''
          ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport ${port} -j RETURN || true
          ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport ${port} -j RETURN || true
        '';
      };
  };
}
