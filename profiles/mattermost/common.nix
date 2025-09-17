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
        proxyPass = "http://127.0.0.1:${toString config.services.mattermost.port}";
      };
      # i really have my doubts about the increased file size in this endpoint, if there are any issues increase it again
      "~ /api/v[0-9]+/(users/)?websocket$" = {
        proxyPass = "http://127.0.0.1:${toString config.services.mattermost.port}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 10M;
        '';
      };
      "~ /api/v[0-9]+/files$" = {
        proxyPass = "http://127.0.0.1:${toString config.services.mattermost.port}";
        proxyWebsockets = true;
        # change the value of the line below this one to increase upload size.
        extraConfig = ''
          client_max_body_size 200M;
        '';
      };
    };
  };
}
