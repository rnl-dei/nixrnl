{
  config,
  lib,
  # pkgs,
  ...
}:
with lib;
let
  cfg = config.dei.gallery;

in
{
  options.dei.gallery = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DEI Gallery (PhotoPrism + home-gallery)";
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/dei/gallery";
      description = "Location of PhotoPrism's state directory";
    };

    mediaDir = mkOption {
      type = types.path;
      description = "Location where media will be stored";
    };
    serverName = mkOption {
      type = types.str;
      description = "Webserver URL";
    };

    serverAliases = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Webserver aliases";
    };

    port = mkOption {
      types = types.int;
      default = 2342;

    };
    settings = mkOption {
      #FIXME add sensible settings
      # - oidc
      # - lang pt
      # - are temp paths set?

      type = types.attrs;
      default = { };
    };

  };

  config = mkIf cfg.enable {
    services.nginx.virtualHosts.gallery = {
      serverName = cfg.serverName;
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxypass = "http://localhost:${cfg.port}";
        proxyWebsockets = true;
      };
    };
    services.photoprism = {
      enable = true;
      originalsPath = "${cfg.mediaDir}";
      storagePath = "${cfg.stateDir}";
      passwordFile = ""; # FIXME
      settings = cfg.settings;
    };
  };
}
