{ config, lib, ... }:
with lib;
let
  cfg = config.dei.leic-alumni;
  sites = filterAttrs (_: v: v.enable) cfg.sites;
  user = config.dei.leic-alumni.user;
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
          description = "Enable LEIC-Alumni application";
        };

        serviceName = mkOption {
          type = types.str;
          description = "Name of the LEIC-Alumni site";
          default = if name == "default" then "leic-alumni" else "leic-alumni-${name}";
          readOnly = true;
        };

        stateDir = mkOption {
          type = types.path;
          default = "/var/lib/dei/leic-alumni/${name}";
          description = "Location of the LEIC-Alumni directory";
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
          default = { } // config.extraEnvironment;
          description = "Environment variables to the uWSGI socket";
        };

        extraEnvironment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment variables to the uWSGI socket";
        };
      };
    };
in
{
  options.dei.leic-alumni = {
    sites = mkOption {
      type = types.attrsOf (types.submodule siteOpts);
      default = { };
      description = "Specification of one or more LEIC-Alumni sites to serve";
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
            "/static".root = "${siteCfg.stateDir}/leicalumni/leicalumni";
          };
        };
      }) sites;
    };

    services.uwsgi = {
      enable = true;
      user = webserver.user;

      # modules/phdms/default.nix also sets uwsgi package - nix complains both can't
      # mkForce the package at the same time
      # package = lib.mkForce phdmsDeps.uwsgiDEI;
      # See comment there on why this is needed.

      group = webserver.group;
      plugins = [ "python3" ];
      instance = {
        type = "emperor";
        vassals = mapAttrs' (_siteName: siteCfg: {
          name = siteCfg.serviceName;
          value = {
            type = "normal";
            chdir = "${siteCfg.stateDir}/leicalumni";
            wsgi-file = "${siteCfg.stateDir}/leicalumni/leicalumni/wsgi.py";
            socket = siteCfg.socket;
            pythonPackages =
              self: with self; [
                django
                django-multiselectfield
                mysqlclient
              ];
            env = mapAttrsToList (n: v: "${n}=${v}") siteCfg.environment;
          };
        }) sites;
      };
    };
  };
}
