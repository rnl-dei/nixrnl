{ pkgs, profiles, ... }:

{
  imports = with profiles; [
    ns.generic
  ];
  options = { };
  config = {

    environment.systemPackages = with pkgs; [
      dig
      dogdns
    ];
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
