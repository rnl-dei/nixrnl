{ config, lib, ... }:
with lib;
let
  cfg = config.services.glitchtip;
in
{
  disabledModules = [ "services/web-apps/glitchtip.nix" ];

  options.services.glitchtip = {
    enable = mkEnableOption (lib.mdDoc "GlitchTip is an open-source, self-hosted error tracking tool.");

    glitchtipImage = mkOption {
      type = types.str;
      description = lib.mdDoc "The GlitchTip image to use.";
      default = "glitchtip/glitchtip:latest";
    };

    port = mkOption {
      type = types.int;
      description = lib.mdDoc "The port to listen on.";
      default = 8000;
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = lib.mdDoc "The path to the secret key file.";
    };

    databaseEnvFile = mkOption {
      type = types.path;
      description = lib.mdDoc "The path to the database environment file.";
    };

    domain = mkOption {
      type = types.str;
      description = lib.mdDoc "The domain to use for GlitchTip.";
      default = "glitchtip.${config.networking.fqdn}";
    };

    fromEmail = mkOption {
      type = types.str;
      description = lib.mdDoc "The email address to send emails from.";
      default = "glitchtip@${config.networking.fqdn}";
    };

    emailUrl = mkOption {
      type = types.str;
      description = lib.mdDoc "The email URL to use.";
      default = "consolemail://";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      description = lib.mdDoc "Extra environment variables to set.";
      default = { };
    };

    stateDir = mkOption {
      type = types.path;
      description = lib.mdDoc "The directory to store data in.";
      default = "/var/lib/glitchtip";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers =
      let
        image = cfg.glitchtipImage;
        dependsOn = [
          "postgres"
          "redis"
        ];
        environmentFiles = [
          cfg.databaseEnvFile
          cfg.secretKeyFile
        ];
        environment = {
          GLITCHTIP_DOMAIN = "https://${cfg.domain}";
          DEFAULT_FROM_EMAIL = cfg.fromEmail;
          EMAIL_URL = cfg.emailUrl;
          PORT = "8000";
          #DATABASE_URL = "postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@postgres:5432/$POSTGRES_DB";
          CELERY_WORKER_AUTOSCALE = "1,3";
          CELERY_WORKER_MAX_TASKS_PER_CHILD = "10000";
        }
        // cfg.extraEnvironment;
        network = "glitchtip"; # FIXME: You need to create this network manually
      in
      {
        postgres = {
          image = "postgres:16";
          volumes = [ "${cfg.stateDir}/postgres:/var/lib/postgresql/data" ];
          environmentFiles = [ cfg.databaseEnvFile ];
          extraOptions = [ "--network=${network}" ];
        };
        redis = {
          image = "redis:latest";
          extraOptions = [ "--network=${network}" ];
        };
        web = {
          inherit
            image
            dependsOn
            environment
            environmentFiles
            ;
          ports = [ "${toString cfg.port}:${environment.PORT}" ];
          volumes = [ "${cfg.stateDir}/uploads:/code/uploads" ];
          extraOptions = [ "--network=${network}" ];
        };
        worker = {
          inherit
            image
            dependsOn
            environment
            environmentFiles
            ;
          cmd = [ "./bin/run-celery-with-beat.sh" ];
          volumes = [ "${cfg.stateDir}/uploads:/code/uploads" ];
          extraOptions = [ "--network=${network}" ];
        };
        migrate = {
          inherit
            image
            dependsOn
            environment
            environmentFiles
            ;
          cmd = [
            "./manage.py"
            "migrate"
          ];
          extraOptions = [ "--network=${network}" ];
        };
      };

    services.nginx.virtualHosts.glitchtip = {
      serverName = cfg.domain;
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
