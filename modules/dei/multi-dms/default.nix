{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let

  #   References:
  #  - https://nixos.org/manual/nixos/stable/#ch-containers
  #  - unironically, `cat (which nixos-container)`
  #  - `systemctl cat container@` 
  #  - https://smallstep.com/docs/step-ca/certificate-authority-server-production/ (For caddy/nginx setup)
  #       (mirror: https://web.archive.org/web/20241108121229/https://smallstep.com/docs/step-ca/certificate-authority-server-production/)

  cfg = config.dei.multi-dms;
  user = cfg.user;
  webserver = config.services.caddy; # TODO: change this
  buildsDir = "${cfg.directory}/builds";
  environmentsDir = "${cfg.directory}/environments";
  # Path to an environment's data. Can only be used in configurations systemd reads directly! (e.g, using this in (...).env files will NOT work.)
  systemdDir = "${environmentsDir}/%i";
  # Directory where caddy will look for extra configuration files.
  caddyConfigsDir = "${cfg.directory}/caddy-configs";
  systemctl = "${pkgs.systemdMinimal}/bin/systemctl";

  common = ''
    # max length for container name is 11
    # therefore, we use hash of branch name and trim to 7, 
    # so the end result is e.g 'dms-a4a8114' (always 11 chars).


    get_db_container_name() {
        local ENVIRONMENT_NAME="$1"

        # Check if arguments are provided
        if [[ -z "$ENVIRONMENT_NAME"  ]]; then
            echo "Usage: create_db_container_name <ENVIRONMENT_NAME>"
            return 1
        fi

        # Hash the input string and convert it to an integer within the specified range
        local hash=$(echo -n "$ENVIRONMENT_NAME" | sha256sum | cut -c1-7)
        db_container_name="dms-$hash" # container name will always be 11 chars, which is max. allowed.
    }

    get_port() {
        local min_port="$1"
        local max_port="$2"
        local ENVIRONMENT_NAME="$3"

        # Check if arguments are provided
        if [[ -z "$ENVIRONMENT_NAME"  ]]; then
            echo "Usage: get_port <min_port> <max_port> <ENVIRONMENT_NAME>"
            return 1
        fi
        # Calculate range
        local range=$(($max_port - $min_port + 1))

        # Hash the input string and convert it to an integer within the specified range
        local hash=$(echo -n "$ENVIRONMENT_NAME" | sha256sum | cut -c1-8)
        local port=$(( (0x$hash % range) + $min_port ))
        echo -n "$port"
    }

    db_dump_file="${cfg.directory}/common/latest.sql"
  '';

  # TODO: use writeShellApplication for auto shellcheck and other things
  preStartScript = pkgs.writeScriptBin "multi-dms-prestart" ''
    #!/usr/bin/env bash
    set -xo pipefail #TODO: add -eu flags

    echo "Start pre-start script for DMS deployment $ENVIRONMENT_NAME"

    ${common}
    get_db_container_name "$ENVIRONMENT_NAME" # sets $db_container_name
    backend_port=$(get_port ${toString cfg.backend.minPort} ${toString cfg.backend.maxPort} $ENVIRONMENT_NAME)
    db_port=$(get_port ${toString cfg.database.minPort} ${toString cfg.database.maxPort} $ENVIRONMENT_NAME)

    create_db() {
      local db_name="$1"
      local db_port="$2"

      local db_container_config=${./db_container.nix}

      # Check if arguments are provided
      if [[ -z "$db_name" || -z "$db_port" ]]; then
        echo "Usage: create_db <db_name> <db_port>"
        return 1
      fi

      nixos-container create "$db_name" \
       --port "tcp:$db_port:3306" \
       --config-file $db_container_config
      
      nixos-container start $db_name
    }

    populate_db() {
      local db_port="$1"

      # Check if arguments are provided
      if [[ -z "$db_port" ]]; then
        echo "Usage: populate_db <db_port>"
        return 1
      fi

      # Because Blatta is too slow for create-destroy DBs on system stop/start,
      # we only populate the DB once and don't automatically destroy it.
      if test -f ${environmentsDir}/$ENVIRONMENT_NAME/_multi-dms-db-init; then
        echo "Refusing to re-populate the database."
        return
      fi

      ${pkgs.mariadb}/bin/mysql \
        -h ${cfg.database.host} \
        --port="$DB_PORT" \
        -u dms -p"$DB_PASSWORD" \
        dms < "$db_dump_file"

      touch ${environmentsDir}/$ENVIRONMENT_NAME/_multi-dms-db-init
    }

    add_caddy_vhost() {
      local ENVIRONMENT_NAME="$1"
      local backend_port="$2"

      # Check if arguments are provided
      if [[ -z "$ENVIRONMENT_NAME" || -z "$backend_port" ]]; then
        echo "Usage: add_caddy_vhost <ENVIRONMENT_NAME> <backend_port>"
        return 1
      fi

      touch ${caddyConfigsDir}/$ENVIRONMENT_NAME

      cat > ${caddyConfigsDir}/$ENVIRONMENT_NAME << EOL
    dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt {
      log {
              output file /var/log/caddy/access-dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt.log
      }

      encode zstd gzip

      handle /raa/* {
              header Access-Control-Allow-Origin "https://rnl.tecnico.ulisboa.pt/"
      }
      handle_path /api/* {
              reverse_proxy "http://localhost:$backend_port"
      }

      # Note: /public/* untested - may be broken!
      handle /public/* {
        root * ${cfg.directory}/deploys/$ENVIRONMENT_NAME/public
        try_files {path} {path}/ /index.txt
        file_server
      }

      handle {
              root * ${cfg.directory}/deploys/$ENVIRONMENT_NAME/www
              try_files {path} {path}/ /index.html
              file_server
      }
    }

    EOL
    ${systemctl} reload caddy
    }

    create_db $db_container_name $db_port
    add_caddy_vhost $ENVIRONMENT_NAME $backend_port
    sleep 1
    populate_db $db_port # TODO: this is very, very, very slow to be doing on-demand.
    #                      Consider an alternative (talk to Carlos/RNL if hypervisor might get faster soon:tm:)
  '';

  # TODO: use writeShellApplication for auto shellcheck and other things
  postStopScript = pkgs.writeScriptBin "multi-dms-poststop" ''
    #!/usr/bin/env bash
    set -xo pipefail #TODO: add -eu flags
    echo "I am stick!"

    ${common}
    get_db_container_name $ENVIRONMENT_NAME # sets $db_container_name

    # Remove caddy virtualhost
    rm ${caddyConfigsDir}/"$ENVIRONMENT_NAME"
    ${systemctl} reload caddy

    # Destroy DB # TODO: actually just stopping because on-demand create/destroy DB is way too slow on blatta.
    nixos-container stop "$db_container_name"
  '';

  # TODO: use writeShellApplication for auto shellcheck and other things
  startScript = pkgs.writeScriptBin "multi-dms-start" ''
    #!/usr/bin/env bash
    exec ${cfg.backend.command}
  '';

  # TODO: use writeShellApplication for auto shellcheck and other things
  deployScript = pkgs.writeScriptBin "multi-dms-deploy" ''
    #!/usr/bin/env bash

    # Add '-x' (e.g -euxo) if debugging this script.
    set -euo pipefail

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

    ENVIRONMENT_NAME=$1


    service_name="multi-dms@$ENVIRONMENT_NAME.service"
    # Check if arguments are provided
    if [[ -z "$ENVIRONMENT_NAME" ]]; then
      echo "Usage: $0 <environment name without 'multi-dms/' prefix> [build timestamp]"
      exit 1
    fi

    # -----
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

    if (! ls $builds_dir &>/dev/null); then
      error_msg "No $builds_dir directory found."
    fi

    LAST_BUILD_STAMP="$(ls -t "$builds_dir" | ${pkgs.gnugrep}/bin/grep '^[[:digit:]]\+$' | head -n 1)"
    if [ -z "$LAST_BUILD_STAMP" ]; then
      error_msg "There is no (last) build. Please copy a build to $builds_dir."
    fi
    BUILD_STAMP="''${2:-$LAST_BUILD_STAMP}"
    BUILD="$builds_dir/$BUILD_STAMP"
    check_build_dir $BUILD

    # Only prompt for confirmation if not specifying a build to use.
    if [[ -z "$2" ]]; then
        BUILD="$builds_dir/$BUILD_STAMP"
        echo -e -n "Are you sure you want to deploy build ''${BLU}$BUILD''${CLR}, commit created at $(${pkgs.toybox}/bin/date -d @$BUILD_STAMP) (y/N)?"
        read -n1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo -e "''${YEL}Aborting...''${CLR}"
          exit 3
        fi
        BUILD_STAMP=$LAST_BUILD_STAMP
    else
      echo "Deploying build ''${BLU}$BUILD''${CLR}, commit time: $(${pkgs.toybox}/bin/date -d @$BUILD_STAMP)..."
    fi

    ENVIRONMENT_DIR="${environmentsDir}/$ENVIRONMENT_NAME"
    # ----
    # Implementation

    ${common}
    get_db_container_name "$ENVIRONMENT_NAME" # sets $db_container_name
    backend_port=$(get_port ${toString cfg.backend.minPort} ${toString cfg.backend.maxPort} $ENVIRONMENT_NAME)
    db_port=$(get_port ${toString cfg.database.minPort} ${toString cfg.database.maxPort} $ENVIRONMENT_NAME)

    # Delete any old deployment leftovers
    echo "Deleting (possible) leftover dms.jar and www...."
    ${systemctl} stop $service_name
    ${pkgs.toybox}/bin/rm -rf "$ENVIRONMENT_DIR/www"
    ${pkgs.toybox}/bin/rm -rf "$ENVIRONMENT_DIR/dms.jar"


    echo "Init new environment..."
    echo "Environment's container DB name is '$db_container_name'".
    echo "You can access it with e.g 'machinectl shell $db_container_name'."
    mkdir -p "$ENVIRONMENT_DIR"
    ${pkgs.toybox}/bin/ln -s "$BUILD/dms.jar" "$ENVIRONMENT_DIR/dms.jar"
    ${pkgs.toybox}/bin/ln -s "$BUILD/www" "$ENVIRONMENT_DIR/www"
    echo "BACKEND_PORT=$backend_port" > "$ENVIRONMENT_DIR/dms.env"
    echo "DB_PORT=$db_port" >> "$ENVIRONMENT_DIR/dms.env"
    echo "DMS_URL"=https://dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt >> "$ENVIRONMENT_DIR/dms.env"


    # Start DMS environment and reload caddy
    echo "Starting service $service_name . The first time might take a while."
    ${systemctl} start $service_name
    echo "Started DMS."
    echo "Environment status:"
    ${systemctl} status $service_name --no-block --no-pager
    echo "Environment URL: https://dms-$ENVIRONMENT_NAME.blatta.rnl.tecnico.ulisboa.pt"

  '';
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
      default = "dms";
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

    database = {
      host = mkOption {
        type = types.str;
        default = "10.233.1.1";
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
          "${cfg.backend.java} -jar ${environmentsDir}/$ENVIRONMENT_NAME/dms.jar --server.port=$BACKEND_PORT"
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
          NIX_PATH = (concatStringsSep ":" config.nix.nixPath); # TODO: ugly, but nixos-container needs it (actually nix-env)
          DB_HOST = cfg.database.host;
          INSTANCE_NAME = "%i"; # TODO: make sure external things aren't using INSTANCE_NAME and deprecate it
          ENVIRONMENT_NAME = "%i";
          DB_NAME = "dms";
          DB_USERNAME = "dms";
          FILES_DIR = "${systemdDir}/data";
          FILES_PUBLIC = "${systemdDir}/www";
        };
        description = "Environment variables common to all DMS deployments";
      };

      environmentFile = mkOption {
        type = types.path;
        default = "${cfg.directory}/common/dms.env";
        description = "Path to the environment file common to all DMS deployments (useful for secrets)";
      };
    };
  };
  imports = [ ./caddy.nix ];

  config = mkIf (cfg.enable) {

    virtualisation = {
      containers.enable = true;
    };
    systemd.tmpfiles.rules = [
      "d ${cfg.directory} 0750 ${user} ${webserver.group} - -"
      "d ${buildsDir} 0750 ${user} ${webserver.group} - -"
      "d ${environmentsDir}/public 0750 ${user} ${webserver.group} - -"
      "d ${caddyConfigsDir} 0750 ${user} ${webserver.group} - -"
    ];

    services.caddy.extraConfig = ''
      import ${caddyConfigsDir}/*
    '';

    # Note 1: DO NOT USE THIS IN PRODUCTION!
    # Note 2: The order of the `handle` directives matter!
    #         The first handle directive that matches will win.
    services.caddy.virtualHosts."fenix-dms-gw.blatta.rnl.tecnico.ulisboa.pt".extraConfig = ''
      encode zstd gzip
      handle {
        redir {header.Referer}login?{query}
      }
    '';

    systemd.services."multi-dms@" = {
      description = "DEI Management System Backend (%i)";
      after = [ "network.target" ];

      path = with pkgs; [
        bash
        nixos-container

        # Dependencies of nixos-container:
        # TODO: this should be upstreamed to nixpkgs, perhaps
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
          "${systemdDir}/dms.env"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };

      unitConfig = {
        ConditionPathExists = "${systemdDir}";
      };
    };

    systemd.services."container@".serviceConfig = {
      # Container creation and population can take some time in slow VMs
      # Looking at you, blatta @ chapek
      TimeoutStartSec = mkForce "10min 0s";
    };

    users.users = mkMerge [
      (mkIf (user == "multi-dms") {
        multi-dms = {
          isNormalUser = true;
          home = cfg.directory;
          homeMode = "750";
          group = webserver.group;
          openssh.authorizedKeys.keys = cfg.builds.authorizedKeys;
        };
      })
      { root.packages = [ cfg.deployScriptPackage ]; }
    ];
  };
}
