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
      database = {
        type = "mysql";
        user = "grafana";
        host = "/run/mysqld/mysqld.sock";
      };
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
        auth_url = "https://gitlab.${config.rnl.domain}/oauth/authorize";
        token_url = "https://gitlab.${config.rnl.domain}/oauth/token";
        api_url = "https://gitlab.${config.rnl.domain}/api/v4";
        allowed_groups = "rnl, dei";
        role_attribute_path = "contains(groups[*], 'rnl') && 'Admin' || 'Viewer'";
      };
    };
  };

  # Use MySQL instead of SQLite for Grafana
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["grafana"];
    ensureUsers = [
      {
        name = "grafana";
        ensurePermissions = {"grafana.*" = "ALL PRIVILEGES";};
      }
    ];
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
