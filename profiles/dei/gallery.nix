{
  config,
<<<<<<< HEAD
  lib,
=======
  # lib,
  # pkgs,
>>>>>>> 415b7bb (profiles/dei/gallery: fix path to password secret)
  ...
}:
let
  cfg = config.services.photoprism;
  serverName = "eventos.dei.tecnico.ulisboa.pt";
  port = 2342;
  title = "Eventos DEI";
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
      PHOTOPRISM_OIDC_REGISTER = toString true;

      # Database configuration
      # TODO
      # PHOTOPRISM_DATABASE_DRIVER = "mysql";
      # PHOTOPRISM_DATABASE_DSN = "";
    };
  };

  systemd.services.photoprism.serviceConfig = {
    LoadCredential = lib.mkForce [
      "PHOTOPRISM_ADMIN_PASSWORD:${config.age.secrets."dei-photoprism-admin-password".path}"
      "PHOTOPRISM_OIDC_SECRET:${config.age.secrets."dei-photoprism-oidc-secret".path}"
    ];
  };

  # Overrides the script set in nixpkgs to also support the oidc secret credential.
  systemd.services.photoprism.script = lib.mkForce ''
    export PHOTOPRISM_ADMIN_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_ADMIN_PASSWORD")
    export PHOTOPRISM_OIDC_SECRET=$(cat "$CREDENTIALS_DIRECTORY/PHOTOPRISM_OIDC_SECRET")
    exec ${cfg.package}/bin/photoprism start
  '';

  rnl.db-cluster = {
    ensureDatabases = [
      "dei-gallery"
    ];
    ensureUsers = [
      {
        name = "dei-gallery";
        ensurePermissions = {
          "dei-gallery.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  age.secrets."dei-photoprism-admin-password".file = ../../secrets/dei-photoprism-admin-password.age;
<<<<<<< HEAD
  age.secrets."dei-photoprism-oidc-secret".file = ../../secrets/dei-photoprism-oidc-secret.age;
=======
>>>>>>> 415b7bb (profiles/dei/gallery: fix path to password secret)

  fileSystems."/var/lib/private/photoprism" = {
    device = "/mnt/data/gallery";
    options = [ "bind" ];
  };

}
