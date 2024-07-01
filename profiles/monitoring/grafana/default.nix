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
      dashboards.settings.providers = [
        {
          name = "RNL-Dashboards";
          options.path = ./dashboards;
        }
      ];
      alerting = {
        rules.path = ./alerts/rules;
        # templates.path = ./alerts/templates;
        # policies.path = ./alerts/policies;
        contactPoints.settings = {
          apiVersion = 1;
          contactPoints = [
            {
              name = "RNL Alertas (Mattermost)";
              orgId = 1;
              receivers = [{
                uid = "t8qo_N-Vk";
                type = "slack";
                settings = {
                  recipient = "alertas";
                  text = "{{ template 'mattermost.alerts' . }}";
                  title = "{{ template 'mattermost.default.title' . }}";
                  url = "$__env{GRAFANA_MATTERMOST_WEBHOOK}";
                };
                disableResolveMessage = true;
              }];
            }
            {
              name = "RNL Infra (Mattermost)";
              orgId = 1;
              receivers = [{
                uid = "BPY2_H-4k";
                type = "slack";
                settings = {
                  recipient = "infra";
                  text = "{{ template 'Only description' }}";
                  url = "$__env{GRAFANA_MATTERMOST_WEBHOOK}";
                };
                disableResolveMessage = false;
              }];
            }
            {
              name = "RNL Infra (Email)";
              orgId = 1;
              receivers = [{
                uid = "qDMyWDa4k";
                type = "email";
                settings = {
                  addresses = ["infra-robots@rnl.tecnico.ulisboa.pt"];
                  singleEmail = false;
                };
                disableResolveMessage = false;
              }];
            }
          ];
        };
      };
      datasources.settings.datasources = {
        "Prometheus" = {
          uid = "PBFA97CFB590B2093";
          type = "prometheus";
          url = "http://localhost:9090";
          access = "proxy";
          isDefault = true;
        };
        "Loki" = {
          uid = "pxCqOS5Iz";
          type = "loki";
          url = "http://localhost:13100";
          access = "proxy";
        };
        "MySQL" = {
          uid = "y7lCbTU7z";
          type = "mysql";
          url = "db.rnl.tecnico.ulisboa.pt";
          access = "proxy";
          user = "$__env{GRAFANA_MYSQL_USER}";
          password = "$__env{GRAFANA_MYSQL_PASSWORD}";
          database = "$__env{GRAFANA_MYSQL_DATABASE}";
        };
        "MySQL Tardis" = {
          uid = "d306f8d7-ec7c-418e-a6fa-c2106c3f23fd";
          type = "mysql";
          url = "localhost";
          access = "proxy";
          user = "$__env{GRAFANA_MYSQL_TARDIS_USER}";
          password = "$__env{GRAFANA_MYSQL_TARDIS_PASSWORD}";
          database = "$__env{GRAFANA_MYSQL_TARDIS_DATABASE}";
        };
      };
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
