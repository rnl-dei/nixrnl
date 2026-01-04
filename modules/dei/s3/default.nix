{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
{
  options.dei.s3 = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable S3 Garage backend";
    };
    serverName = mkOption {
      type = types.str;
      default = "";
      description = "Webserver URL";
    };
    environmentPath = mkOption {
      type = types.path;
      default = /var/lib/garage.env;
      description = "Path to environmnet File potentially including secrets";
    };
  };
  config = {

    services.nginx.virtualHosts."${config.dei.s3.serverName}" = {
      serverName = "${config.dei.s3.serverName}";
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 0;
      '';
      locations."/" = {
        proxyPass = "http://[::1]:3900";
      };
    };
    services.garage = {
      enable = mkDefault config.dei.s3.enable;
      package = pkgs.garage_2;
      environmentFile = mkDefault config.dei.s3.environmentPath;
      settings = {
        replication_factor = 1;
        rpc_bind_addr = "[::]:3901";
        s3_api = {
          api_bind_addr = "[::]:3900";
          s3_region = "garage";
          root_domain = "${config.dei.s3.serverName}";
        };
        admin = {
          api_bind_addr = "[::]:3903";
          metrics_require_token = true;
        };
      };
    };
  };
}
