{ config, profiles, ... }:

{
  imports = with profiles; [
    ns.generic
  ];
  options = { };
  config = {
    age.secrets."rnl-slack-config" = {
      file = ../../secrets/rnl-slack-conf.age;
      owner = "root";
      name = "rnl-slack.conf";
    };
    rnl.githook = {
      enable = true;
      hooks.dns-config = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/dns.git";
        path = "/var/lib/dns-config";
        directoryMode = "0755";
      };
    };
    services.bind = {
      enable = true;
      zones."rnl.tecnico.ulisboa.pt" = {
        master = true;
        file = "/var/lib/dns-config/rnl.tecnico.ulisboa.pt";
        slaves = [ "any" ];
      };
      zones."rnl.ist.utl.pt" = {
        master = true;
        file = "/var/lib/dns-config/rnl.tecnico.ulisboa.pt";
        slaves = [ "any" ];
      };
      zones."89.16.10.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/10.16.89.zone";
      };
      zones."86.16.10.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/10.16.86.zone";
      };
      zones."82.16.10.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/10.16.82.zone";
      };
      zones."81.16.10.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/10.16.81.zone";
      };
      zones."80.16.10.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/10.16.80.zone";
      };
      zones."154.136.193.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/193.136.154.zone";
      };
      zones."164.136.193.in-addr.arpa" = {
        master = true;
        file = "/var/lib/dns-config/193.136.164.zone";
      };
      zones."8.0.0.0.0.1.2.0.9.6.0.1.0.0.2.ip6.arpa" = {
        master = true;
        file = "/var/lib/dns-config/2001:690:2100:8.zone";
      };

    };
  };
}
