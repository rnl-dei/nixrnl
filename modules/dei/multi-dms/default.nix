{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dei.multi-dms;
  user = cfg.user;
  webserver = config.services.caddy; # TODO: change this
  buildsDir = "${cfg.directory}/builds";
  deploysDir = "${cfg.directory}/deploys-available";
  enabledSitesDir = "${cfg.directory}/deploys-enabled";
in
{
  options.dei.multi-dms = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable DEI Management System application";
    };

    user = mkOption {
      type = types.str;
      default = "multi-dms";
      description = "User to run the DMS service as";
    };

    directory = mkOption {
      type = types.path;
      default = "/var/lib/dei/multi-dms";
      description = "Base directory to store DMS files";
    };
    builds = {
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "SSH public keys authorized to perform deployments (usually CI ssh keys)";
      };
    };

    # TODO rg: deploy script

    backend = {
      java = mkOption {
        type = types.str;
        default = "${pkgs.openjdk17}/bin/java";
        description = "Path to the Java executable";
      };

      # TODO rg: use random port inside interval (See /var/lib/dms in blatta)
      # TODO: create getPort shellScript here
      # TODO: change descriptions
      minPort = mkOption {
        type = types.int;
        default = 30000;
        description = "Port of the backend server";
      };
      maxPort = mkOption {
        type = types.int;
        default = 40000;
        description = "Port of the backend server";
      };

      command = mkOption {
        type = types.str;
        default =
          # FIXME: dont use static port!
          # Maybe use unix socket...?
          "${config.backend.java} -jar ${config.backend.jar} --server.port=34677"
          + (concatStringsSep " " config.backend.extraArgs);
        description = "Command to start the DMS backend";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra arguments to pass to the backend server";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {
          DB_HOST = config.database.host;
          DB_PORT = toString config.database.port;
          DB_NAME = config.database.name;
          DB_USERNAME = config.database.user;
          DMS_INSTANCE = "%i";
          FILES_DIR = "${cfg.deploysDir}/%i/data";
          FILES_PUBLIC = "${cfg.deploysDir}/%i/www";
        };
        description = "Environment variables common to all DMS deployments";
      };

      environmentFile = mkOption {
        type = types.path;
        default = "${cfg.directory}/dms.env";
        description = "Path to the environment file common to all DMS deployments (useful for secrets)";
      };
    };
  };

  config = mkIf (cfg.enable) {
    systemd.tmpfiles.rules = [
      "d ${cfg.directory} 0750 ${user} ${webserver.group} - -"
      "d ${buildsDir} 0750 ${user} ${webserver.group} - -"
      "d ${deploysDir}/public 0750 ${user} ${webserver.group} - -"
      "d ${enabledSitesDir}/data 0700 ${user} ${webserver.group} - -"
    ];

    # TODO: test this intensively!
    services.nginx.defaultListen = [
      { addr = "127.0.0.80"; }
      # ipv6 has only one loopback address: using only ipv4.
      # https://serverfault.com/questions/193377/ipv6-loopback-addresses-equivalent-to-127-x-x-x
    ];

    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET
    # FIXME RG: DON'T DEPLOY TO DEI YET

    services.caddy = {
      enable = true;
      acmeCA = config.security.acme.default.server;
      inherit (config.security.acme.defaults) email;
      globalConfig = ''
        grace_period 10s
        skip_install_trust
      '';
      extraConfig = ''
        import ${enabledSitesDir}/*
      '';

      # TODO: remove this one virtualHost. only added for testing
      # Note: the order of the handle directives matter!
      # The first handle directive that matches will win.
      virtualHosts =
        {
          "multi-dms-default.blatta.rnl.tecnico.ulisboa.pt".extraConfig = ''
            encode zstd gzip

            handle /raa/* {
              header Access-Control-Allow-Origin "https://rnl.tecnico.ulisboa.pt/"
            }
            handle /api/* {
              reverse_proxy "http://127.0.0.1:34677" #FIXME: rg
            }
            # Note: purposefully didnt write /public handle because it seems wrong/doesnt do anything
            handle { 
              #root * ${cfg.deploysDir}/%i/www FIXME: rg
              root * ${cfg.deploysDir}/default/www
              file_server
            }
          '';
        }
        // (lib.mapAttrs (
          _vhostName: _vhostConfig: {
            # https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#https
            extraConfig = ''
              reverse_proxy https://127.0.0.80 {
              	header_up Host {upstream_hostport}
              }
            '';
          }
        ));
    };

    systemd.services."multi-dms@" = {
      description = "DEI Management System Backend (%i)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = cfg.backend.environment;
      script = ''
        ${cfg.backend.command}
      '';

      serviceConfig = {
        User = user;
        Group = webserver.group;
        EnvironmentFile = [
          cfg.backend.environmentFile
          "${cfg.deploysDir}/%i/dms.env"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
        ConditionPathExists = "${cfg.deploysDir}/%i";
      };
    };

    users.users = mkMerge [
      (mkIf (user == "multi-dms") {
        dms = {
          isNormalUser = true;
          home = cfg.directory;
          homeMode = "750";
          group = webserver.group;
          openssh.authorizedKeys.keys = cfg.builds.authorizedKeys;
        };
      })
      # FIXME: rg { root.packages = mapAttrsToList (_: siteCfg: siteCfg.deployScriptPackage) sites; }
    ];
  };
}
