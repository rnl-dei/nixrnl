{
  config,
  lib,
  pkgs,
  ...
}: {
  services.grafana = {
    enable = true;
    package = pkgs.unstable.grafana;
    settings = {
      server = {
        root_url = "https://${config.services.nginx.virtualHosts.grafana.serverName}";
        http_port = 3000;
      };
      smtp = {
        enabled = true;
        host = "${config.rnl.mailserver.host}:${toString config.rnl.mailserver.port}";
        from_name = "Grafana @ RNL";
        from_address = lib.mkDefault "noreply@grafana.${config.rnl.domain}";
      };
      # Use local sqlite database
      analytics = {
        reporting_enabled = false;
        feedback_enabled = false;
      };
      security = {
        admin_password = "$__env{GRAFANA_SECURITY_ADMIN_PASSWORD}";
        cookie_secure = true;
        cookie_samesite = "strict";
        allow_embedding = true;
      };
      "auth.anonymous" = {
        enabled = true;
      };
      "auth.gitlab" = {
        enabled = true;
        allow_sign_up = true;
        client_id = "$__env{GRAFANA_AUTH_GITLAB_CLIENT_ID}";
        client_secret = "$__env{GRAFANA_AUTH_GITLAB_CLIENT_SECRET}";
        scopes = "read_api";
        auth_url = "https://gitlab.rnl.tecnico.ulisboa.pt/oauth/authorize";
        token_url = "https://gitlab.rnl.tecnico.ulisboa.pt/oauth/token";
        api_url = "https://gitlab.rnl.tecnico.ulisboa.pt/api/v4";
        allowed_groups = "rnl, dei";
        role_attribute_path = "is_admin && 'Admin' || contains(groups[*], 'rnl') && 'Editor' || 'Viewer'";
      };
    };
    provision = {
      enable = true;
      # TODO: Add provisioning of datasources, alerting and dashboards
    };
  };

  services.nginx.upstreams.grafana.servers = {
    "localhost:${toString config.services.grafana.settings.server.http_port}" = {};
  };

  services.nginx.virtualHosts.grafana = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    enableACME = true;
    forceSSL = lib.mkForce true; # Cookies won't work without SSL
    locations = {
      "/" = {
        proxyPass = "http://grafana";
      };
      "/api/live" = {
        proxyPass = "http://grafana";
        proxyWebsockets = true;
      };
    };
  };
}
