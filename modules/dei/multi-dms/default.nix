{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let

  #   References:
  #  - https://smallstep.com/docs/step-ca/certificate-authority-server-production/ (For caddy/nginx setup)
  #       (mirror: https://web.archive.org/web/20241108121229/https://smallstep.com/docs/step-ca/certificate-authority-server-production/)

  cfg = config.dei.multi-dms;
  user = cfg.user;
  webserver = config.services.caddy;
  buildsDir = "${cfg.dataDir}/builds";
  environmentsDir = "${cfg.dataDir}/environments";
  # Shortcut for the path to an environment's data. Can only be used in configurations systemd reads directly! (e.g, using this variable in (...).env files will NOT work. E.g, Using this inside systemd's `serviceConfig` definition will work.)
  environmentDirSystemd = "${environmentsDir}/%i";
  # Directory where caddy will look for extra configuration files.
  caddyConfigsDir = "${cfg.dataDir}/caddy-configs";

  common = ''
    get_port() {
        local min_port="$1"
        local max_port="$2"

        # Calculate range
        local range=$((max_port - min_port + 1))

        # Hash the input string and convert it to an integer within the specified range
        local hash
        hash=$(echo -n "$ENVIRONMENT_NAME" | sha256sum | cut -c1-8)
        local port=$(( (0x$hash % range) + min_port ))
        echo -n "$port"
    }

  '';

  preStartScript = pkgs.writeShellApplication {
    name = "multi-dms-prestart";

    runtimeInputs = with pkgs; [
      mariadb
      systemd
      docker
      wait4x # tool to wait for port or service to enter requested state
    ];
    text = ''
      echo "Start pre-start script for DMS deployment $ENVIRONMENT_NAME"

      ${common}
      backend_port=$(get_port ${toString cfg.backend.minPort} ${toString cfg.backend.maxPort})
      db_port=$(get_port ${toString cfg.database.minPort} ${toString cfg.database.maxPort})

      create_db() { 
        # ENVIRONMENT_NAME=potato
        # DB_PORT=69420
        IMG_NAME=mariadb:10.11.11
        ENV_FILE=${cfg.backend.environmentFile}
        DUMP_FILE=$(readlink -f ${cfg.dataDir}/common/latest.sql)
        DUMP_FILE_NAME="$(basename "$DUMP_FILE")"
        
        docker container create \
           --hostname="$ENVIRONMENT_NAME" \
           -p "$db_port":3306 \
           --rm \
           --name="$ENVIRONMENT_NAME" \
           --volume "$DUMP_FILE:/docker-entrypoint-initdb.d/$DUMP_FILE_NAME:ro" \
           --env-file="$ENV_FILE" \
           $IMG_NAME \
           --character-set-server=utf8mb4 \
           --collation-server=utf8mb4_unicode_ci
        
        docker container start "$ENVIRONMENT_NAME"
      }


      add_caddy_vhost() {
        local backend_port="$1"

        # Check if arguments are provided
        if [[ -z "$backend_port" ]]; then
          echo "Usage: add_caddy_vhost <backend_port>"
          return 1
        fi

        touch "${caddyConfigsDir}/$ENVIRONMENT_NAME"

        cat > "${caddyConfigsDir}/$ENVIRONMENT_NAME" << EOL
      dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt {
        log {
                output file /var/log/caddy/access-dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt.log
        }

        encode zstd gzip
        header +Set-Cookie "multi_dms_host=dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt; Domain=blatta.rnl.tecnico.ulisboa.pt"
         

        handle /raa/* {
                header Access-Control-Allow-Origin "https://rnl.tecnico.ulisboa.pt/"
        }
        handle_path /api/* {
                reverse_proxy "http://localhost:$backend_port"
        }

        # Note: /public/* untested - may be broken!
        handle /public/* {
          root * ${cfg.dataDir}/environments/$ENVIRONMENT_NAME/public
          try_files {path} {path}/ /index.txt
          file_server
        }

        handle {
          root * ${cfg.dataDir}/environments/$ENVIRONMENT_NAME/www
          try_files {path} {path}/ /index.html
          file_server
        }
      }

      EOL
      systemctl reload caddy
      }
      create_db

      # Wait for database to be up and running
      # wait4x is very noisy while waiting for mariadb to be alive (even with --quiet) - redirect everything to /dev/null.
      wait4x --quiet --timeout 300s mysql "dms:$DB_PASSWORD@tcp(localhost:$db_port)/dms" > /dev/null 2>&1

      add_caddy_vhost "$backend_port"
    '';

  };

  postStopScript = pkgs.writeShellApplication {
    name = "multi-dms-poststop";

    runtimeInputs = with pkgs; [
      systemd
      docker
    ];
    text = ''
      echo "Start multi-dms post stop script"

      ${common}

      # Remove caddy virtualhost
      rm -f ${caddyConfigsDir}/"$ENVIRONMENT_NAME"
      systemctl reload caddy

      # Destroy database container and all its anonymous volumes.
      # Don't fail if container does not exist/is already stopped/etc.
      docker container stop "$ENVIRONMENT_NAME" || true
    '';
  };

  startScript = pkgs.writeShellApplication {
    name = "multi-dms-start";
    text = ''
      exec ${cfg.backend.command}
    '';
  };

  deployScript = pkgs.writeShellApplication {
    name = "multi-dms-deploy";

    runtimeInputs = with pkgs; [
      systemd
      gnugrep
      # Note: use toybox instead of busybox because busybox `date` does not
      # Because `date` from busybox does not seem to support parsing UNIX timestamps.
      toybox
    ];
    text = ''
      # Add '-x' (e.g -euxo) if debugging this script.
      set -euo pipefail

      # Colors
      RED="\e[1;31m"
      #GRN="\e[1;32m"
      YEL="\e[1;93m"
      BLU="\e[1;94m"
      CLR="\e[0m"

      error_msg() {
        echo -e "''${RED}ERROR:''${CLR} $1"
        exit 1
      }


      # Check if arguments are provided
      if  [[ $# -ne 1 && $# -ne 2 ]]; then
        echo "Usage: $0 <environment name without 'multi-dms/' prefix> [build timestamp]"
        exit 1
      fi

      ENVIRONMENT_NAME=$1
      # -----
      service_name="multi-dms@$ENVIRONMENT_NAME.service"
      builds_dir="${buildsDir}/$ENVIRONMENT_NAME"
      echo "Environment name: $ENVIRONMENT_NAME"
      echo "Build directory: $builds_dir"
      # ----    

      check_build_dir() {
        local DIRECTORY="$1"
        if [ ! -d "$DIRECTORY" ]; then
          error_msg "Could not find build $DIRECTORY"
        elif [ ! -f "$DIRECTORY/dms.jar" ]; then
          error_msg "Missing $DIRECTORY/dms.jar"
        elif [ ! -d "$DIRECTORY/www" ]; then
          error_msg "Missing $DIRECTORY/www"
        fi
      }

      if (! ls "$builds_dir" &>/dev/null); then
        error_msg "No $builds_dir directory found."
      fi

      # shellcheck disable=SC2012 # (info): Use find instead of ls to better handle non-alphanumeric filenames.
      # shellcheck disable=SC2010 # (warning): Don't use ls | grep. Use a glob or a for loop with a condition to allow non-alphanumeric filenames.
      LAST_BUILD_STAMP="$(ls -t "$builds_dir" | grep '^[[:digit:]]\+$' | head -n 1)"
      if [ -z "$LAST_BUILD_STAMP" ]; then
        error_msg "There is no (last) build. Please copy a build to $builds_dir."
      fi
      BUILD_STAMP="''${2:-$LAST_BUILD_STAMP}"
      BUILD="$builds_dir/$BUILD_STAMP"
      check_build_dir "$BUILD"

      # Only prompt for confirmation if not specifying a build to use.
      if [[ $# -ne 2 ]]; then
          BUILD="$builds_dir/$BUILD_STAMP"
          echo -e -n "Are you sure you want to deploy build ''${BLU}$BUILD''${CLR}, commit created at $(date -d @"$BUILD_STAMP") (y/N)?"
          read -n1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "''${YEL}Aborting...''${CLR}"
            exit 3
          fi
          BUILD_STAMP=$LAST_BUILD_STAMP
      else
        echo "Deploying build $BUILD, commit timestamp: $(date -d @"$BUILD_STAMP")..."
      fi

      ENVIRONMENT_DIR="${environmentsDir}/$ENVIRONMENT_NAME"
      # ----
      # Implementation

      ${common}
      backend_port=$(get_port ${toString cfg.backend.minPort} ${toString cfg.backend.maxPort})
      db_port=$(get_port ${toString cfg.database.minPort} ${toString cfg.database.maxPort})

      # Delete any old deployment leftovers
      echo "Deleting (possible) leftover dms.jar and www...."
      systemctl stop "$service_name"
      rm -rf "$ENVIRONMENT_DIR/www"
      rm -rf "$ENVIRONMENT_DIR/dms.jar"


      echo "Init new environment..."
      mkdir -p "$ENVIRONMENT_DIR"
      ln -s "$BUILD/dms.jar" "$ENVIRONMENT_DIR/dms.jar"
      ln -s "$BUILD/www" "$ENVIRONMENT_DIR/www"
      echo "BACKEND_PORT=$backend_port" > "$ENVIRONMENT_DIR/dms.env"
      echo "DB_PORT=$db_port" >> "$ENVIRONMENT_DIR/dms.env"
      echo "DMS_URL=https://dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt" >> "$ENVIRONMENT_DIR/dms.env"


      # Start DMS environment and reload caddy
      echo "Starting service $service_name - this might take a minute." 
      systemctl start "$service_name"
      echo "Started DMS."
      echo "Environment status:"
      systemctl status "$service_name" --no-block --no-pager
      echo "Environment URL: https://dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt"
    '';
  };
in
{
  options.dei.multi-dms = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable DEI Management System application (Multi-Environments)";
    };

    user = mkOption {
      type = types.str;
      default = "dms";
      description = "User to run the DMS environments as";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/dei/multi-dms";
      description = "Base data directory to store DMS environments' files";
    };
    builds = {
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "SSH public keys authorized to perform deployments (usually CI ssh keys)";
      };
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Database host address";
      };
      minPort = mkOption {
        type = types.int;
        default = 32000;
        description = "Min port for the DB server";
      };
      maxPort = mkOption {
        type = types.int;
        default = 34000;
        description = "Max port for the DB server";
      };
    };

    deployScriptPackage = mkOption {
      type = types.package;
      default = deployScript;
      description = "Package containing the deploy script";
    };

    backend = {
      java = mkOption {
        type = types.str;
        default = "${pkgs.openjdk17}/bin/java";
        description = "Path to the Java executable";
      };

      minPort = mkOption {
        type = types.int;
        default = 36000;
        description = "Min port for the backend server";
      };
      maxPort = mkOption {
        type = types.int;
        default = 38000;
        description = "Max port for the backend server";
      };

      command = mkOption {
        type = types.str;
        default =
          "${cfg.backend.java} -jar ${environmentsDir}/\"$ENVIRONMENT_NAME\"/dms.jar --server.port=\"$BACKEND_PORT\""
          + (concatStringsSep " " cfg.backend.extraArgs);
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
          NIX_PATH = (concatStringsSep ":" config.nix.nixPath); # ugly, but nixos-container needs it (actually nix-env)
          DB_HOST = cfg.database.host;
          ENVIRONMENT_NAME = "%i";
          DB_NAME = "dms";
          DB_USERNAME = "dms";
          FILES_DIR = "${environmentDirSystemd}/data";
          FILES_PUBLIC = "${environmentDirSystemd}/www";
        };
        description = "Environment variables common to all DMS deployments";
      };

      environmentFile = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/common/dms.env";
        description = "Path to the environment file common to all DMS deployments (useful for secrets)";
      };
    };
  };
  imports = [ ./caddy.nix ];

  config = mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${user} ${webserver.group} - -"
      "d ${buildsDir} 0750 ${user} ${webserver.group} - -"
      "d ${environmentsDir} 0750 ${user} ${webserver.group} - -"
      "d ${caddyConfigsDir} 0750 ${user} ${webserver.group} - -"
      "Z /etc/nixos-containers 0771 ${user} root - -"
      "Z /var/lib/nixos-containers 0771 ${user} root - -"
    ];

    services.caddy.extraConfig = ''
      import ${caddyConfigsDir}/*
    '';

    # Note 1: DO NOT USE THIS IN PRODUCTION!
    #         Using the `Referer` header as the base for the redirect URL is inherently insecure as this is user-controlled,
    #         and could probably be used maliciously.
    #         However for development environments this poses no risk, and there seems to be no clearer alternative
    #         For using one oAuth2 application for multiple distinct instances.
    #         (For obvious reasons, we can't dynamically create and/or destroy oauth2 applications in Fénix for each DMS instance.)
    # Note 2: The order of the `handle` directives matter!
    #         The first handle directive that matches will win.
    services.caddy.virtualHosts."fenix-dms-gw.blatta.rnl.tecnico.ulisboa.pt".extraConfig = ''
      encode zstd gzip

      handle {
        # redir {header.Referer}login?{query}
        redir https://{http.request.cookie.multi_dms_host}/login?{query}
      }
    '';

    systemd.services."multi-dms@" = {
      description = "DEI Management System Backend (%i)";
      after = [ "network.target" ];
      restartIfChanged = false;
      stopIfChanged = false;

      path = with pkgs; [
        bash
        nixos-container

        # Dependencies of nixos-container:
        # TODO: this should probably be upstreamed to nixpkgs
        util-linux # dependency of nixos-container (e.g, it tries to do `exec (...) mountpoint`)
        systemd # dependency of nixos-container (and possibly prestart and poststop scripts)
        nix # nix-env
      ];

      environment = cfg.backend.environment;

      serviceConfig = {
        User = user;
        Group = webserver.group;
        ExecStart = "${startScript}/bin/multi-dms-start";
        ExecStartPre = "+${preStartScript}/bin/multi-dms-prestart";
        ExecStopPost = "+${postStopScript}/bin/multi-dms-poststop";
        TimeoutSec = "10min 0s";

        EnvironmentFile = [
          cfg.backend.environmentFile
          "${environmentDirSystemd}/dms.env"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };

      unitConfig = {
        ConditionPathExists = environmentDirSystemd;
      };
    };

    systemd.services."container@".serviceConfig = {
      # Container creation and population can take some time in slow VMs
      # Looking at you, blatta @ chapek
      TimeoutStartSec = mkForce "10min 0s";
    };

    # Enable polkit with a custom rule:
    # This allows the `dms` user (the user that both CI connects with and that DMS services run as)
    # to manage all `multi-dms` systemd services.
    # In particular, we want CI to start/stop `multi-dms@<branch_name>.service` as required.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          RegExp('multi-dms@[A-Za-z0-9_-]+.service').test(action.lookup("unit")) === true &&
          subject.user == "dms") {
          return polkit.Result.YES;
      }
      });
    '';

    users.users = mkMerge [
      (mkIf (user == "multi-dms") {
        multi-dms = {
          isNormalUser = true;
          home = cfg.dataDir;
          homeMode = "750";
          group = webserver.group;
          openssh.authorizedKeys.keys = cfg.builds.authorizedKeys;
        };
      })
      { dms.packages = [ cfg.deployScriptPackage ]; }
    ];
  };
}
