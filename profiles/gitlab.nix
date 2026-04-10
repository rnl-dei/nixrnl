{
  config,
  profiles,
  pkgs,
  ...
}:
{
  imports = with profiles; [
    webserver
  ];

  services.nginx.virtualHosts.gitlab-staging = {
    serverName = "gitlab-staging.rnl.tecnico.ulisboa.pt";
    serverAliases = [
      "git-staging.rnl.tecnico.ulisboa.pt"
      "registry-staging.rnl.tecnico.ulisboa.pt"
    ];
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
  };

  age.secrets = {
    "database-password" = {
      file = ../secrets/gitlab/database-password.age;
      owner = "git";
    };

    "root-password" = {
      file = ../secrets/gitlab/root-password.age;
      owner = "git";
    };

    "base-secret" = {
      file = ../secrets/gitlab/base-secret.age;
      owner = "git";
    };

    "db-secret" = {
      file = ../secrets/gitlab/db-secret.age;
      owner = "git";
    };

    "otp-secret" = {
      file = ../secrets/gitlab/otp-secret.age;
      owner = "git";
    };

    "jws-secret" = {
      file = ../secrets/gitlab/jws-secret.age;
      owner = "git";
    };

    "active-record-primary" = {
      file = ../secrets/gitlab/active-record-primary.age;
      owner = "git";
    };

    "active-record-deterministic" = {
      file = ../secrets/gitlab/active-record-deterministic.age;
      owner = "git";
    };

    "active-record-salt" = {
      file = ../secrets/gitlab/active-record-salt.age;
      owner = "git";
    };

    "registry-cert" = {
      file = ../secrets/gitlab/registry-cert.age;
      owner = "docker-registry";
      group = "docker-registry";
    };

    "registry-key" = {
      file = ../secrets/gitlab/registry-key.age;
      owner = "docker-registry";
      group = "docker-registry";
    };

    "gitlab-oauth" = {
      file = ../secrets/gitlab/oauth-secret.age;
      owner = "git";
    };

    "imap-password" = {
      file = ../secrets/gitlab/imap-password.age;
      owner = "git";
    };

    "dsa-key" = {
      file = ../secrets/gitlab/ssh-dsa-priv.age;
      path = "/etc/ssh/gitlab_ssh_host_dsa_key";
    };

    "ecdsa-key" = {
      file = ../secrets/gitlab/ssh-ecdsa-priv.age;
      path = "/etc/ssh/gitlab_ssh_host_ecdsa_key";
    };

    "ed25519-key" = {
      file = ../secrets/gitlab/ssh-ed25519-priv.age;
      path = "/etc/ssh/gitlab_ssh_host_ed25519_key";
    };

    "rsa-key" = {
      file = ../secrets/gitlab/ssh-rsa-priv.age;
      path = "/etc/ssh/gitlab_ssh_host_rsa_key";
    };
  };

  services.gitlab = {
    enable = true;

    databaseCreateLocally = true;
    https = true;

    databaseUsername = "git";
    databasePasswordFile = "${config.age.secrets."database-password".path}";
    initialRootPasswordFile = "${config.age.secrets."root-password".path}";

    secrets = {
      secretFile = "${config.age.secrets."base-secret".path}";
      dbFile = "${config.age.secrets."db-secret".path}";
      otpFile = "${config.age.secrets."otp-secret".path}";
      jwsFile = "${config.age.secrets."jws-secret".path}";
      activeRecordPrimaryKeyFile = "${config.age.secrets."active-record-primary".path}";
      activeRecordDeterministicKeyFile = "${config.age.secrets."active-record-deterministic".path}";
      activeRecordSaltFile = "${config.age.secrets."active-record-salt".path}";
    };

    registry = {
      enable = true;
      externalAddress = "registry-staging.rnl.tecnico.ulisboa.pt";
      defaultForProjects = false;
      certFile = "${config.age.secrets."registry-cert".path}";
      keyFile = "${config.age.secrets."registry-key".path}";
      package = pkgs.gitlab-container-registry;
      externalPort = 5050;
    };

    packages.gitlab = pkgs.gitlab-ee;

    port = 443;

    group = "git";
    user = "git"; # try to avoid ssh issues with default user "gitlab"

    puma.workers = 31;

    smtp = {
      address = "comsat.rnl.tecnico.ulisboa.pt";
      domain = "gitlab-staging.rnl.tecnico.ulisboa.pt";
      enable = true;
      opensslVerifyMode = "none";
    };

    extraConfig = {
      gitlab_default_theme = 7;

      gitlab_default_projects_features_issues = true;
      gitlab_default_projects_features_merge_requests = true;
      gitlab_default_projects_features_wiki = false;
      gitlab_default_projects_features_snippets = false;
      gitlab_default_projects_features_builds = true;

      gitlab_email_enabled = true;
      gitlab_email_from = "noreply@gitlab.rnl.tecnico.ulisboa.pt";
      gitlab_email_display_name = "GitLab @ RNL";
      gitlab_email_reply_to = "noreply@gitlab.rnl.tecnico.ulisboa.pt";
      incoming_email_enabled = true;
      incoming_email_address = "gitlab-incoming@rnl.tecnico.ulisboa.pt";

      #### IMAP Settings
      incoming_email_email = "gitlab-incoming";
      incoming_email_host = "comsat.rnl.tecnico.ulisboa.pt";
      incoming_email_port = 993;
      incoming_email_ssl = true;
      incoming_email_start_tls = false;
      service_desk_email_delivery_method = "sidekiq";
      incoming_email_mailbox_name = "inbox";
      incoming_email_expunge_deleted = true;
      incoming_email_delivery_method = "sidekiq";

      incoming_email_password = {
        _secret = "${config.age.secrets."imap-password".path}";
      };

      password_authentication_enabled_for_web_ui = false;
      password_authentication_enabled_for_git_http = false;

      impersonation_enabled = true;

      omniauth = {
        enabled = true;
        allow_single_sign_on = [ "oauth2_generic" ];
        auto_link_user = [ "oauth2_generic" ];
        sync_email_from_provider = [ "oauth2_generic" ];
        sync_profile_from_provider = [ "oauth2_generic" ];
        sync_profile_attributes = [
          "username"
          "name"
        ];
        block_auto_created_users = false;

        providers = [
          {
            name = "oauth2_generic";
            icon =
              "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAEE0lEQVR4Ae2aA9ArSRCA+2zbtn3Fs23bKp5t23fJRs+2bdvKzuxubF7+qO9mT8"
              + "HT7h/O26+qS+nUTH+rEWwQgSBXoRlDgCHAEGAIaGDs4yB4wRAP3jnBj1eM9OIJfV24g43yL+DqUT6cFehAhpTMYz+SxkXhLDJi2SJ+tyyOx/ZR+BRgWpXAf1kayeJOVvG/33"
              + "4v+S2RK+KFQzx8CXhuRhhLeXNetOz3swd4sJRIRxEP76XwIWBnu4jJXBFLuWdioCxnd5uElbw9P8qHgMtG+LCSW8b5y3K2tRIsYjmOtUk+BDwwKYiV3DDGV5W3MJTFUl6fG+"
              + "FDwKNTqgVcP8ZflXfuIDeui+ewgIhDpDTuYhW3FAHlUT4e4FkAByNBQ8B+3WU8rLvyXxzcg2oRwN7+7H8bjQO7yq0rYJI3g6UEMgVNAk7pr+CmWBHN8SrAEGAI2NFC8bxBbn"
              + "VqXMl4T0b97dT+Ln4F/BtbW5xYCZsqN+YrYAgwBBgCDAGGAGeKGwGsFs2Y1il6GpvcggJYLXoegSW1EBBsBQGsFs2YxcncCGC1aBdAe3J0B/QAzVjoy9wIsJKXQDM2ehk3Ai"
              + "zkUtBMN7oXFwJMziJYI3uCLgSygoM7YDnoRiAfaW3wx+VxJuG/GCqndQnYyuTEab5MWXy0KKbj9pc+AN1YlTPbflXYLp8OnUIga9pYwCroNBb6dtsKsEhvQKexK/tonRgd0U"
              + "vB+yYG2QJn8wSYnEnoLe8NNcEi/bC5DbOTHKl8ERkFRCaiOQKs9BuoGQ5yFAgktzkN9xZTWMqSSLYq5/EpIazk4uHeWgrIgsN9ONQUgX6/OY0PltJYAjvoVJXzzPQqAWzLq5"
              + "YCvoKaw0ZTFuLfVOOvzY1gKbkiskFNWc6r5TnsG1/DZ594oGtod6gLAnlsUx3Y0y6pt30pZw5wl+V0WZvEfwl3FPCY3nINrz59EOoG4lZgIRM21YkDustlx1smejJ4ZE+FHX"
              + "RQj8Jki6hCk3m8pJbPvkUcrfaxrnRVDgXBGdpUZ9hQ9sqRPuwjpnBZJMvO+qmFk7+KHuv+A5+dHsLtBVrD4okfrP4DoSFY5Vv1dHIbs7N+ByBs5DpoKBbx25Y5CG2hn0LD6Y"
              + "3bgJkMa37xpL/63DeFQYHdwCQubuKVnwtD3DtDU7HLh4BZXNsEAcvB4d0fWgI27BQIaVjxZnE1dCEHQUthoUeDmYgNELBK/RS3JD2kg+v7ThBnQ3f3vtDSsDlD+a5SjYKOhN"
              + "7+XaEt6I3bg1Uy13Ruzz67bYeVvqDOzfWv6qTBQh+CtsYun6/z5bgcHNKpwAH/riV00/C8/6IOcLjDRm4Dgfg2MqylYJOuBK5R9xzp72zPrqT4nLqM5fDuAlsMDulc9XPJJl"
              + "QO90nQJP4Ea2uIYNSGiwkAAAAASUVORK5CYII=";
            label = "Técnico ID";
            app_id = "851490151334311";
            app_secret = {
              _secret = "${config.age.secrets."gitlab-oauth".path}";
            };
            args = {

              client_options = {
                site = "https://fenix.tecnico.ulisboa.pt";
                user_info_url = "/api/fenix/v1/person";
                authorize_url = "/oauth/userdialog";
                token_url = "/oauth/access_token";
              };

              user_response_structure = {
                id_path = "username";
                attributes = {
                  uid = "username";
                  nickname = "username";
                  email = "institutionalEmail";
                  name = "displayName";
                  image = [
                    "photo"
                    "data"
                  ];
                };
              };
              strategy_class = "OmniAuth::Strategies::OAuth2Generic";
            };
          }
        ];
      };

      prometheus_monitoring = {
        enable = true;
      };

      monitoring_whitelist = [
        "193.136.164.82"
        "2001:690:2100:81::82"
      ]; # Tardis IPs

      ### GitLab user privileges
      gitlab_username_changing_enabled = false;

      # Disable unused features
      geo_registry_replication_enabled = false;
      gitlab_kas_enabled = false;
      terraform_state_enabled = false;
    };
  };

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/gitlab_ssh_host_dsa_key";
        type = "dsa";
      }
      {
        path = "/etc/ssh/gitlab_ssh_host_ecdsa_key";
        type = "ecdsa";
      }
      {
        path = "/etc/ssh/gitlab_ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/gitlab_ssh_host_rsa_key";
        type = "rsa";
      }
    ];
  };

  environment.etc = {
    "ssh/gitlab_ssh_host_dsa_key.pub" = {
      text = "ssh-dss AAAAB3NzaC1kc3MAAACBAJRPaOLJS+gQcaZ0IM+5kpDaL0xUiwDmkzmZ2K9P6kxbp7kAEIMy7FYkSe6kuASw/5gf0t9cwer1moMc4rtfEAlFewQQl2SpKv6ANodcXVIho4aP6T9bOwu/Xay3j8DC8OncXJh8CVWxF4Tz8XiXYnFvliYbv4SWr08qcC/qIQZZAAAAFQCIN0XSFW5GIP5EQqJ3Y6pEkZkdSwAAAIAa7ssRKAIUprSF5k1bhNqRnt6+xzW56nuSC3ZIomiyQuhYl3dBN489kpozSzw9k6AgZdWKj3rIHVJoMGdDyyjnN69CQj2V+8jHFtePhlYB2HOY+Gkj2gEc9FnW+URh1hT+o2gmym2QMuGI5vDraN80XDbTM5clvyn44V99bO+G9wAAAIBIWYyqNizKoHQ1X2/r+AwqdiLsgM304oq9OCJnFvbTufxyWMwLGyJEB1GnFwPDnmf7YaySKnMp8E6mzjmdKrHTyBYHG1lYE1iTtoCLR9Nz2hXTW1R0JUgljS32TZZNHnkrIuvFTDP0lMu8MSzS3VYRL5ClFv5yglazJ2cAUh7C/w==";
      mode = "0644";
    };

    "ssh/gitlab_ssh_host_ecdsa_key.pub" = {
      text = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPsEaA4Mnz052omCpTmVS5UQNcNvMjfXwI7gHIx3SgIiO/tUlAP1ZY1vpfh95iuyZpc1DGvXao4Gq9k38QdoPEA=";
      mode = "0644";
    };

    "ssh/gitlab_ssh_host_ed25519_key.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGaP0hqVNDA7CPiPC4zd75JKaNpR2kefJ7qmVEiPtCK";
      mode = "0644";
    };

    "ssh/gitlab_ssh_host_rsa_key.pub" = {
      text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSaX9GDDsWY676og7KpMs2wsuqMuvy7iC7WBMO8DuwgrkvwdGfIBkm8bkoLje1ialg/IlcBBGut8I6mIJ8ZeIw5KlrEo4qP3svhkCQNOR2KnqggQRNYOevarW5315j2hBPGEw4MF4Cx9vL3Rj6Vrb+w0okzPJFSmC3li1coCD5cRKAWuvdrvE8I8k0FuN1TzHR2FA7hWpA90Y9c625Qu6gdRkYuBmPYk+GmvovIszQSjx28vvRsaKRwvkXTnhY45zWWQl4PZXWxFZHGeV5D51tQW4Qi7vbrL257RHt1Ssj7Gvd3mKsKe5dDST7/Wa/sS5/A740S2OfmJ6HODdsuce5AG4wfP+wHQrmu4AMtOXkFQ8P8TQJntOLGUDeOYkQK3zSoG/DNkUuUae30FPIWm+ju5HCP3Ei9KlanBXe67s35DTSHhgG6lI4qVo0cCoHVma8GF5eCUhrD1nnk4DBZFBSrsXNBds8wzNDyY6Un+SQ4V8+ot3BMZoUGbZuh50HVn8=";
      mode = "0644";
    };
  };
}
