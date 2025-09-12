{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.mattermost = {
    enable = true;
    package = pkgs.unstable.mattermost;
    siteName = lib.mkDefault "Mattermost @ RNL";
    siteUrl = lib.mkDefault "https://${config.networking.fqdn}";
    host = "127.0.0.1";
    port = 8065;
    database.create = lib.mkForce false;
  };

  services.nginx.upstreams.mattermost.servers = {
    "${config.services.mattermost.host}" = { };
  };

  services.nginx.virtualHosts.mattermost = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://mattermost";
      };
      "~ /api/v[0-9]+/(users/)?websocket$" = {
        proxyPass = "http://mattermost";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };
  };
}
