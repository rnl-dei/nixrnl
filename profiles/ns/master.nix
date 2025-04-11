{ config, ... }:

{
  options = { };
  config = {
    imports = with profiles; [
      ns.generic
    ];
    age.secrets."ns-access-token" = {
      file = ../../secrets/ns-githook-token.age;
      owner = "root";
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
    services.bind = {
      enable = true;
      zones."rnl.tecnico.ulisboa.pt" = {
        master = true;
        slaves = [ "193.136.164.2" ];
        file = "/var/lib/dns-config/rnl.tecnico.ulisboa.pt";
      };
      zones."rnl.ist.utl.pt" = {
        master = true;
        slaves = [ "193.136.164.2" ];
        file = "/var/lib/dns-config/rnl.tecnico.ulisboa.pt";
      };
    };
  };
}
