{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.photoprism;
  serverName = "eventos.dei.tecnico.ulisboa.pt";
  port = 2342;
  title = "Eventos DEI";
  dbName = "deigallery";

  sourceSecrets = ''
    PHOTOPRISM_ADMIN_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_ADMIN_PASSWORD")
    PHOTOPRISM_OIDC_SECRET=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_OIDC_SECRET")
    PHOTOPRISM_DATABASE_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_DATABASE_PASSWORD")
    export PHOTOPRISM_ADMIN_PASSWORD
    export PHOTOPRISM_OIDC_SECRET
    export PHOTOPRISM_DATABASE_PASSWORD
  '';

  mgmtPkg = pkgs.writeShellApplication {
    name = "photoprism-mgmt";

    runtimeEnv = cfg.settings;

    runtimeInputs = [ cfg.package ];

    text = ''
      export CREDENTIALS_DIRECTORY=/run/credentials/photoprism.service
      ${sourceSecrets}
      exec photoprism "$@"
    '';
  };
in
{
  # https://nixos.wiki/wiki/PhotoPrism
  services.nginx.virtualHosts.gallery = {
    inherit serverName;
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString port}";
      proxyWebsockets = true;
    };
  };
  services.photoprism = {
    enable = true;
    originalsPath = "/var/lib/photoprism/originals";
    # Replaced with explicit `LoadCredential`
    settings = {
      PHOTOPRISM_INDEX_WORKERS = toString 1;
      PHOTOPRISM_INDEX_SCHEDULE = "@daily";
      PHOTOPRISM_DISABLE_SETTINGS = toString true;
      PHOTOPRISM_DISABLE_RESTART = toString true;
      PHOTOPRISM_DISABLE_WEBDAV = toString true;
      PHOTOPRISM_DISABLE_PLACES = toString true;
      PHOTOPRISM_DISABLE_TENSORFLOW = toString true;
      PHOTOPRISM_DEFAULT_LOCALE = "pt_PT";
      PHOTOPRISM_DEFAULT_TIMEZONE = "GMT";
      PHOTOPRISM_APP_NAME = title;
      PHOTOPRISM_SITE_URL = "https://${serverName}";
      PHOTOPRISM_SITE_AUTHOR = "Departamento de Engenharia Informática";
      PHOTOPRISM_SITE_TITLE = title;
      PHOTOPRISM_SITE_CAPTION = "Galeria do Departamento de Engenharia Informática do IST";
      PHOTOPRISM_DISABLE_TLS = toString true;

      # OpenID Connect configuration
      PHOTOPRISM_OIDC_URI = "https://gitlab.rnl.tecnico.ulisboa.pt";
      PHOTOPRISM_OIDC_SCOPES = "openid email profile"; # default also includes 'address' which gitlab doesn't seem to mention
      PHOTOPRISM_OIDC_CLIENT = "9e0d78e249f0a6de0adf645684c39ff6b0beb84e485f56bac03e049db0ab3fde";
      PHOTOPRISM_OIDC_REGISTER = toString false;
      PHOTOPRISM_OIDC_PROVIDER = "Fénix";
      # PHOTOPRISM_OIDC_ICON = ""; # TODO: what kind of image is photoprism expecting??

      # Database configuration
      PHOTOPRISM_DATABASE_DRIVER = "mysql";
      PHOTOPRISM_DATABASE_SERVER = "db.rnl.tecnico.ulisboa.pt:3306";
      PHOTOPRISM_DATABASE_NAME = "${dbName}";
      PHOTOPRISM_DATABASE_USER = "${dbName}";
    };
  };

  systemd.services.photoprism.serviceConfig = {
    LoadCredential = lib.mkForce [
      "PHOTOPRISM_ADMIN_PASSWORD:${config.age.secrets."dei-photoprism-admin-password".path}"
      "PHOTOPRISM_OIDC_SECRET:${config.age.secrets."dei-photoprism-oidc-secret".path}"
      "PHOTOPRISM_DATABASE_PASSWORD:${config.age.secrets."dei-photoprism-db-password".path}"
    ];
  };

  # Overrides the script set in nixpkgs to also support the oidc secret credential.
  systemd.services.photoprism.script = lib.mkForce ''
    ${sourceSecrets}
    exec ${cfg.package}/bin/photoprism start
  '';

  age.secrets = {
    "dei-photoprism-admin-password".file = ../../secrets/dei-photoprism-admin-password.age;
    "dei-photoprism-oidc-secret".file = ../../secrets/dei-photoprism-oidc-secret.age;
    "dei-photoprism-db-password".file = ../../secrets/dei-photoprism-db-password.age;
  };

  rnl.db-cluster = {
    ensureDatabases = [
      "${dbName}"
    ];
    ensureUsers = [
      {
        name = "${dbName}";
        ensurePermissions = {
          "${dbName}.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
  
  fileSystems."/var/lib/private/photoprism" = {
    device = "/mnt/data/gallery";
    options = [ "bind" ];
  };

  users.users.root.packages = [ mgmtPkg ];
}
