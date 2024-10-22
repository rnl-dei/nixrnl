{ lib, ... }:
{
  # Warning: do not use domain names in these rules, at the risk of the
  # firewall starting before a nameserver could be fetched from the DHCP
  # server, in which case you might not have a firewall at all.
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        # Block all incomming connections traffic except SSH and "ping".
        chain input {
          type filter hook input priority 0;

          # accept any localhost traffic
          iifname lo accept

          # accept traffic originated from us
          ct state {established, related} accept

          # accept SSH connections (required for a server)
          tcp dport 22 accept

          # accept node-exporter
          tcp dport 9100 accept

          # Allow ICMP
          ip protocol icmp accept

          accept
        }

        # Allow all outgoing connections.
        chain output {
          type filter hook output priority 0;

          # accept any localhost traffic
          iifname lo accept
          ip daddr 127.0.0.0/8 accept

          # accept traffic originated from us
          ct state {established, related} accept


          # Allow DNS
          # ip daddr 193.136.164.1 udp dport domain accept
          # ip daddr 193.136.164.2 udp dport domain accept

          # # kerberos.tecnico.ulisboa.pt
          # ip daddr 193.136.128.55 tcp dport {kerberos,kerberos-adm} accept
          # # ldap.tecnico.ulisboa.pt
          # ip daddr 193.136.128.31 tcp dport {ldap,ldaps} accept

          # # Gitlab @ RNL
          # ip daddr 193.136.164.27 tcp dport {http,https} accept
          # ip daddr 193.136.164.19 tcp dport {http,https} accept

          # # NTP
          # ip daddr 193.136.164.4 udp dport ntp accept

          ip daddr 193.136.164.8 tcp dport {http,https} accept

          tcp dport { 22, 80, 443 } drop
          accept
        }
      }
    '';
  };

  boot.kernel.sysctl."net.ipv4.ip_default_ttl" = 123;

  systemd.services.nftables = {
    serviceConfig = {
      Restart = "on-failure";
    };
  };
}
