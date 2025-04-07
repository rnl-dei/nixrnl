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
    services.bind = {
      enable = true;
      zones."rnl.tecnico.ulisboa.pt" = {
        master = false;
        masters = [ "193.136.164.1" ];
      };
    };
  };
}
