{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.ist-delegate-election.nixosModules.ist-delegate-election];

  age.secrets."ist-delegate-election.env" = {
    file = ../secrets/ist-delegate-election-env.age;
    owner = config.services.ist-delegate-election.user;
    mode = "0400";
  };

  services.ist-delegate-election = {
    enable = true;
    fqdn = lib.mkDefault "https://delegados.rnl.tecnico.ulisboa.pt";

    settingsFile = config.age.secrets."ist-delegate-election.env".path;
  };

  services.nginx.upstreams.ist-delegate-election.servers = {
    "[::1]:${toString config.services.ist-delegate-election.port}" = {};
  };

  services.nginx.virtualHosts.ist-delegate-election = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    serverAliases = ["delegados.rnl.tecnico.ulisboa.pt"];
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://ist-delegate-election";
    };
  };
}
