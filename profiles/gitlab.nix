{ ... }:
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
    };

    port = 443;

    user = "git"; # try to avoid ssh issues with default user "gitlab"

    smtp = {
      address = "comsat.rnl.tecnico.ulisboa.pt";
      domain = "gitlab-staging.rnl.tecnico.ulisboa.pt";
      enable = true;
      opensslVerifyMode = "none";
    };

    extraConfig = {
      incoming_email_password = {
        _secret = "${config.age.secrets."imap-password".path}";
      };

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
              "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAEE0lEQVR4Ae2aA9ArSRCA+2zbtn3Fs23bKp"
              + "5t23fJRs+2bdvKzuxubF7+qO9mT8HT7h/O26+qS+nUTH+rEWwQgSBXoRlDgCHAEGAIaGDs4yB4wRAP3jnBj1"
              + "eM9OIJfV24g43yL+DqUT6cFehAhpTMYz+SxkXhL>";
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
    };

    extraGitlabRb = ''
      gitlab_rails['gitlab_default_theme'] = 7

      ### Default project feature settings
      gitlab_rails['gitlab_default_projects_features_issues'] = true
      gitlab_rails['gitlab_default_projects_features_merge_requests'] = true
      gitlab_rails['gitlab_default_projects_features_wiki'] = false
      gitlab_rails['gitlab_default_projects_features_snippets'] = false
      gitlab_rails['gitlab_default_projects_features_builds'] = true

      gitlab_rails['gitlab_email_enabled'] = true
      ##! If your SMTP server does not like the default 'From: gitlab@gitlab.example.com'
      ##! can change the 'From' with this setting.
      gitlab_rails['gitlab_email_from'] = 'noreply@gitlab.rnl.tecnico.ulisboa.pt'
      gitlab_rails['gitlab_email_display_name'] = 'GitLab @ RNL'
      gitlab_rails['gitlab_email_reply_to'] = 'noreply@gitlab.rnl.tecnico.ulisboa.pt'

      ### Reply by email
      ###! Allow users to comment on issues and merge requests by replying to
      ###! notification emails.
      ###! Docs: https://docs.gitlab.com/ee/administration/reply_by_email.html
      gitlab_rails['incoming_email_enabled'] = true
      gitlab_rails['incoming_email_address'] = "gitlab-incoming@rnl.tecnico.ulisboa.pt"

      #### IMAP Settings
      gitlab_rails['incoming_email_email'] = "gitlab-incoming"
      gitlab_rails['incoming_email_host'] = "comsat.rnl.tecnico.ulisboa.pt"
      gitlab_rails['incoming_email_port'] = 993
      gitlab_rails['incoming_email_ssl'] = true
      gitlab_rails['incoming_email_start_tls'] = false
      gitlab_rails['service_desk_email_delivery_method'] = "sidekiq"
      gitlab_rails['incoming_email_mailbox_name'] = "inbox"
      gitlab_rails['incoming_email_expunge_deleted'] = true
      gitlab_rails['incoming_email_delivery_method'] = "sidekiq"

      gitlab_rails['impersonation_enabled'] = true

      ### Monitoring
      prometheus_monitoring['enable'] = true
      gitlab_rails['monitoring_whitelist'] = ['193.136.164.82', '2001:690:2100:81::82'] # Tardis IPs

      ### GitLab user privileges
      gitlab_rails['gitlab_username_changing_enabled'] = false

      # disable unused features
      gitlab_rails['geo_registry_replication_enabled'] = false
      gitlab_rails['gitlab_kas_enabled'] = false
      gitlab_rails['terraform_state_enabled'] = false
    '';
  };

  services.openssh = {
    enable = true;
    hostKeys =
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
        };
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
