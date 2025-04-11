{ pkgs, ... }:

{
  options = { };
  config = {
    environment.systemPackages = with pkgs; [
      dig
      dogdns
    ];
    #environment.etc."oldstyleDNS".source = ./oldDNS;
    #environment.etc."coredns-hosts".source = ./hosts;
    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
    services.bind = {
      enable = true;
      #      extraConfig="max-cache-size 768M;";
      cacheNetworks = [
        "127.0.0.1"
        "193.136.164.0/24" # a nossa gama 164
        "193.136.154.0/24" # a nossa gama 154
        "2001:690:2100:80::/58" # toda a RNL via IPv6
        "192.168.0.0/16" # IPs privados internos da RNL
        "10.16.80.0/20" # IPs privados IST da RNL
      ];
      zones."rnl.tecnico.ulisboa.pt" = {
        master = false;
        file = "/var/lib/slave-dns-config/rnl.tecnico.ulisboa.pt";
        masters = [ "193.136.164.1" ];
      };
      zones."rnl.ist.utl.pt" = {
        master = false;
        masters = [ "193.136.164.1" ];
        file = "/var/lib/slave-dns-config/rnl.ist.utl.pt";
      };
      # zones."." = {
      #  file ="/var/lib/slave-dns-config/named.cache";
      #   extraConfig="type hint;";
      #};
    };
  };
}
