{ config, pkgs, ... }:

{
  options = { };
  config = {
    environment.systemPackages = with pkgs; [
      dig
      dogdns
      git
      #the following are needed to build the dns packaged
      pull-repo
      gnumake
      ipv6calc
      gnum4
    ];
    age.secrets."ns-access-token" = {
      file = ../../secrets/ns-githook-token.age;
      owner = "hedgedoc";
    };
    rnl.githook = {
      enable = true;
      hooks.dns-config = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/dns.git";
        path = "/var/lib/dns-config";
        directoryMode = "0755";
        #secretFile = config.age.secrets."ns-access-token".path;
      };
    };
    #environment.etc."oldstyleDNS".source = ./oldDNS;
    #environment.etc."coredns-hosts".source = ./hosts;
    services.bind = {
      enable = true;
      zones."rnl.tecnico.ulisboa.pt" = {
        master = true;
        file = "/var/lib/dns-config/rnl.tecnico.ulisboa.pt";
      };
    };
  };
}
