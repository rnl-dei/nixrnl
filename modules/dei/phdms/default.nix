{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dei.phdms;
  sites = filterAttrs (_: v: v.enable) cfg.sites;
  webserver = config.services.nginx;
  uwsgi = config.services.uwsgi;

  siteOpts =
    {
      options,
      config,
      name,
      ...
    }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable PhD DEI Management System application";
        };

        serviceName = mkOption {
          type = types.str;
          description = "Name of the PhDMS site";
          default = if name == "default" then "phdms" else "phdms-${name}";
          readOnly = true;
        };

        stateDir = mkOption {
          type = types.path;
          default = "/var/lib/dei/phdms/${name}";
          description = "Location of the PhDMS directory";
        };

        serverName = mkOption {
          type = types.str;
          default = "${name}";
          description = "Webserver URL";
        };

        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Webserver aliases";
        };

        socket = mkOption {
          type = types.str;
          default = "${uwsgi.runDir}/${config.serviceName}.sock";
          description = "Path to the uWSGI socket";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {
            PATH_WKHTMLTOPDF = "${pkgs.allowOpenSSL.wkhtmltopdf-bin}/bin/wkhtmltopdf";
            PATH = makeBinPath ([ pkgs.pdftk ] ++ config.extraPackages);
          } // config.extraEnvironment;
          description = "Environment variables to the uWSGI socket";
        };

        extraEnvironment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment variables to the uWSGI socket";
        };

        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages to install";
        };
      };
    };
in
{
  options.dei.phdms = {
    sites = mkOption {
      type = types.attrsOf (types.submodule siteOpts);
      default = { };
      description = "Specification of one or more PhDMS sites to serve";
    };
  };

  config = mkIf (sites != { }) {
    services.nginx = {
      enable = true;
      virtualHosts = mapAttrs' (_siteName: siteCfg: {
        name = siteCfg.serviceName;
        value = {
          serverName = mkDefault "${siteCfg.serverName}";
          serverAliases = mkDefault siteCfg.serverAliases;
          enableACME = mkDefault true;
          forceSSL = mkDefault true;
          locations = {
            "/".extraConfig = ''
              uwsgi_pass unix:${uwsgi.instance.vassals."${siteCfg.serviceName}".socket};
              include ${config.services.nginx.package}/conf/uwsgi_params;
            '';
            "/static".root = "${siteCfg.stateDir}/deic";
          };
        };
      }) sites;
    };

    systemd.tmpfiles.rules = flatten (
      mapAttrsToList (_: siteCfg: [
        "d ${siteCfg.stateDir}/deic/media 0750 ${webserver.user} ${webserver.group} - -"
        "d ${siteCfg.stateDir}/deic/media/uploads 0750 ${webserver.user} ${webserver.group} - -"
      ]) sites
    );

    services.uwsgi = {
      enable = true;
      user = webserver.user;
      group = webserver.group;
      plugins = [ "python3" ];
      instance = {
        type = "emperor";
        vassals = mapAttrs' (_siteName: siteCfg: {
          name = siteCfg.serviceName;
          value = {
            type = "normal";
            chdir = "${siteCfg.stateDir}/deic";
            wsgi-file = "${siteCfg.stateDir}/deic/deic/wsgi.py";
            socket = siteCfg.socket;
            virtualenv = "${siteCfg.stateDir}/venv";
            env = mapAttrsToList (n: v: "${n}=${v}") siteCfg.environment;
          };
        }) sites;
      };
    };
  };
}
