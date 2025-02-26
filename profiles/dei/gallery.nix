{
  config,
  # lib,
  # pkgs,
  ...
}:
# with lib;
let
  serverName = "eventos.dei.tecnico.ulisboa.pt";
  # required by systemd.
  # mediaDir = "/var/lib/private/photoprism";
  port = 2342;
  title = "Eventos DEI";
in
{
  # https://nixos.wiki/wiki/PhotoPrism
  # NOTE: Ensure mediaDir and its subfolders (originals, storage) exist before photoprism starts.
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
    # originalsPath = "${mediaDir}/originals";
    # originalsPath = "/var/lib/private/photoprism/originals";
    originalsPath = "/var/lib/photoprism/originals";

    # storagePath = "${mediaDir}/storage";
    passwordFile = config.age.secrets."dei-photoprism-admin-password".path;
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

      # PHOTOPRISM_DATABASE_DRIVER = "mysql";
      # PHOTOPRISM_DATABASE_DSN = "TODO" #TODO;
      #TODO

      #TODO

    };
  };

  rnl.db-cluster = {
    ensureDatabases = [
      "gallery"
    ];
    ensureUsers = [
      {
        name = "gallery";
        ensurePermissions = {
          "gallery.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  age.secrets."dei-photoprism-admin-password".file = ../../secrets/dei-photoprism-admin-password.age;

  fileSystems."/var/lib/private/photoprism" = {
    device = "/mnt/data/gallery";
    options = [ "bind" ];
  };

}
