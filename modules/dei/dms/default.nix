{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.dei.dms;
  sites = filterAttrs (_: v: v.enable) cfg.sites;
  user = config.dei.dms.user;
  webserver = config.services.nginx;

  siteOpts = {
    options,
    config,
    lib,
    name,
    ...
  }: {
    options = {
      enable = mkEnableOption "DEI Management System application";

      stateDir = mkOption {
        type = types.path;
        default = "/var/lib/dei/dms/${name}";
        description = "Location of the DMS state directory";
      };

      serverName = mkOption {
        type = types.str;
        default = "${name}";
        description = "Webserver URL";
      };

      serverAliases = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Webserver aliases";
      };

      deployScriptPackage = mkOption {
        type = types.package;
        default = mkDeployScript name;
        description = "Package containing the deploy script";
      };

      database = {
        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "Database host address";
        };

        port = mkOption {
          type = types.int;
          default = 3306;
          description = "Database port";
        };

        name = mkOption {
          type = types.str;
          default = "dms";
          description = "Database name";
        };

        user = mkOption {
          type = types.str;
          default = "dms";
          description = "Database user";
        };

        passwordFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to the file containing the database password";
        };
      };

      backend = {
        java = mkOption {
          type = types.str;
          default = "${pkgs.openjdk17}/bin/java";
          description = "Path to the Java executable";
        };

        jar = mkOption {
          type = types.path;
          default = "${config.stateDir}/backend/dms.jar";
          description = "Path to the DMS JAR file";
        };

        port = mkOption {
          type = types.int;
          default = 8080;
          description = "Port of the backend server";
        };

        command = mkOption {
          type = types.str;
          default = "${config.backend.java} -jar ${config.backend.jar} --server.port=${toString config.backend.port}";
          description = "Command to start the DMS backend";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {
            DB_HOST = config.database.host;
            DB_PORT = toString config.database.port;
            DB_NAME = config.database.name;
            DB_USERNAME = config.database.user;
          };
          description = "Environment variables to set for the DMS service";
        };

        extraEnvironment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Extra environment variables to set for the DMS service";
        };

        environmentFile = mkOption {
          type = types.path;
          default = "${config.stateDir}/dms.env";
          description = "Path to the environment file (usefull for secrets)";
        };
      };
    };
  };

  mkDeployScript = site:
    pkgs.writeScriptBin "deploy-dms-${site}" ''
      set -e # stop on error

      # Colors
      RED="\e[1;31m"
      GRN="\e[1;32m"
      YEL="\e[1;93m"
      BLU="\e[1;94m"
      CLR="\e[0m"

      error_msg() {
        echo -e "''${RED}ERROR:''${CLR} $1"
        exit 1
      }

      check_build_dir() {
        DIRECTORY="$1"
        if [ ! -d "$DIRECTORY" ]; then
          error_msg "Could not find build $DIRECTORY"
        elif [ ! -f "$DIRECTORY/dms.jar" ]; then
          error_msg "Missing $DIRECTORY/dms.jar"
        elif [ ! -d "$DIRECTORY/www" ]; then
          error_msg "Missing $DIRECTORY/www"
        fi
      }

      HOSTNAME="''${HOSTNAME:-$(cat /proc/sys/kernel/hostname)}"
      BUILDS_DIR="${cfg.builds.directory}"
      STATE_DIR="${cfg.sites."${site}".stateDir}"
      SITE="${site}"

      if (! ls $BUILDS_DIR &>/dev/null); then
        error_msg "No $BUILDS_DIR directory found."
      fi

      LAST_BUILD_STAMP="$(ls -t $BUILDS_DIR | ${pkgs.gnugrep}/bin/grep '^[[:digit:]]\+$' | head -n 1)"
      if [ -z "$LAST_BUILD_STAMP" ]; then
        error_msg "There is no build. Please copy a build to $BUILDS_DIR."
      fi
      BUILD_STAMP="''${1:-$LAST_BUILD_STAMP}"
      BUILD="$BUILDS_DIR/$BUILD_STAMP"

      check_build_dir $BUILD

      if [ -f "$STATE_DIR/dms.jar" ]; then
        echo "Running build is $(${pkgs.toybox}/bin/readlink $STATE_DIR/dms.jar)"
      fi

      read -p "Are you sure you want to deploy build $BUILD, created at $(${pkgs.toybox}/bin/date -d @$BUILD_STAMP) (y/N)? " -n1 -r
      echo

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "''${YEL}Aborting...''${CLR}"
        exit 3
      fi

      # Stop service
      ${pkgs.systemd}/bin/systemctl stop "dms-${site}.service"


      # Delete old build
      ${pkgs.toybox}/bin/rm -rf "$STATE_DIR/dms.jar" "$STATE_DIR/www"

      # Create symbolic links to new build
      ${pkgs.toybox}/bin/ln -s "$BUILD/dms.jar" "$STATE_DIR/dms.jar"
      ${pkgs.toybox}/bin/ln -s "$BUILD/www" "$STATE_DIR/www"

      # Start service
      ${pkgs.systemd}/bin/systemctl start "dms-${site}.service"

      echo -e "''${GRN}DMS ${site} successfully deployed.''${CLR}"
    '';
in {
  options.dei.dms = {
    sites = mkOption {
      type = types.attrsOf (types.submodule siteOpts);
      default = {};
      description = "Specification of one or more DMS sites to serve";
    };

    user = mkOption {
      type = types.str;
      default = "dms";
      description = "User to run the DMS service as";
    };

    builds = {
      directory = mkOption {
        type = types.path;
        default = "/var/lib/dei/dms/builds";
        description = "Directory to store the DMS build artifacts";
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "SSH public keys authorized to do the deploy";
      };
    };
  };

  config = mkIf (sites != {}) {
    systemd.tmpfiles.rules =
      flatten (mapAttrsToList (_: siteCfg: [
          "d ${siteCfg.stateDir} 0750 ${user} ${webserver.group} - -"
          "d ${siteCfg.stateDir}/public 0750 ${user} ${webserver.group} - -"
          "d ${siteCfg.stateDir}/data 0700 ${user} ${webserver.group} - -"
        ])
        sites)
      ++ [
        "d ${cfg.builds.directory} 0750 ${user} ${webserver.group} - -"
      ];

    services.nginx = {
      enable = true;
      virtualHosts =
        mapAttrs' (siteName: siteCfg: {
          name = "dms-${siteName}";
          value = {
            serverName = mkDefault "${siteCfg.serverName}";
            serverAliases = mkDefault siteCfg.serverAliases;
            root = "${siteCfg.stateDir}/www";
            enableACME = mkDefault true;
            forceSSL = mkDefault true;
            locations = {
              "/" = {};
              "/raa/" = {
                extraConfig = ''
                  add_header Access-Control-Allow-Origin 'https://rnl.tecnico.ulisboa.pt/';
                '';
              };
              "/api/" = {
                proxyPass = "http://127.0.0.1:${toString siteCfg.backend.port}";
                proxyWebsockets = true;
              };
              "/public/" = {
                root = "${siteCfg.stateDir}";
                index = "file.txt";
              };
            };
          };
        })
        sites;
    };

    systemd.services =
      mapAttrs' (siteName: siteCfg: {
        name = "dms-${siteName}";
        value = {
          description = "DEI Management System Backend (${siteName})";
          after = ["network.target"];
          wantedBy = ["multi-user.target"];

          environment = siteCfg.backend.environment;
          script = ''
            ${siteCfg.backend.command}
          '';

          serviceConfig = {
            User = user;
            Group = webserver.group;
            EnvironmentFile = siteCfg.backend.environmentFile;
            Restart = "on-failure";
          };
        };
      })
      sites;

    users.users = mkMerge [
      (mkIf (user == "dms") {
        dms = {
          isNormalUser = true;
          home = "/var/lib/dms";
          group = webserver.group;
          openssh.authorizedKeys.keys = cfg.builds.authorizedKeys;
        };
      })
      {
        root.packages = mapAttrsToList (_: siteCfg: siteCfg.deployScriptPackage) sites;
      }
    ];
  };
}
