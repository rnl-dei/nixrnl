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
    };
  };
}
