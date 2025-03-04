{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dei.odeio;
  sites = filterAttrs (_: v: v.enable) cfg.sites;
  user = cfg.user;
  webserver = config.services.nginx;

  siteOpts =
    {
      options,
      # config,
      # lib,
      name,
      ...
    }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable ODEIO static website";
        };

        serviceName = mkOption {
          type = types.str;
          description = "Name of the ODEIO service";
          default = if name == "default" then "odeio" else "odeio-${name}";
          readOnly = true;
        };

        stateDir = mkOption {
          type = types.path;
          default = "/var/lib/dei/odeio/${name}";
          description = "Location of the ODEIO state directory";
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

        deployScriptPackage = mkOption {
          type = types.package;
          default = mkDeployScript name;
          description = "Package containing the deploy script";
        };
      };
    };

  mkDeployScript =
    site:
    pkgs.writeShellApplication {
      name = "deploy-${cfg.sites."${site}".serviceName}";

      runtimeInputs = with pkgs; [
        gnugrep
        toybox
        systemd
      ];

      text = ''
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
          fi
        }

        HOSTNAME="''${HOSTNAME:-$(cat /proc/sys/kernel/hostname)}"
        BUILDS_DIR="${cfg.builds.directory}"
        STATE_DIR="${cfg.sites."${site}".stateDir}"

        if (! ls $BUILDS_DIR &>/dev/null); then
          error_msg "No $BUILDS_DIR directory found."
        fi

        # shellcheck disable=SC2012 # (info): Use find instead of ls to better handle non-alphanumeric filenames.
        # shellcheck disable=SC2010 # (warning): Don't use ls | grep. Use a glob or a for loop with a condition to allow non-alphanumeric filenames.
        LAST_BUILD_STAMP="$(ls -t $BUILDS_DIR | grep '^[[:digit:]]\+$' | head -n 1)"
        if [ -z "$LAST_BUILD_STAMP" ]; then
          error_msg "There is no build. Please copy a build to $BUILDS_DIR."
        fi
        BUILD_STAMP="''${1:-$LAST_BUILD_STAMP}"
        BUILD="$BUILDS_DIR/$BUILD_STAMP"

        check_build_dir "$BUILD"

        echo -e -n "Are you sure you want to deploy build ''${BLU}$BUILD''${CLR}, created at $(date -d @"$BUILD_STAMP") (y/N)? "
        read -n1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo -e "''${YEL}Aborting...''${CLR}"
          exit 3
        fi

        # Delete old build
        rm -rf "$STATE_DIR/www"

        # Create symbolic links to new build
        ln -s "$BUILD" "$STATE_DIR/www"


        echo -e "''${GRN}ODEIO ${site} successfully deployed.''${CLR}"
      '';
    };
in
{
  options.dei.odeio = {
    sites = mkOption {
      type = types.attrsOf (types.submodule siteOpts);
      default = { };
      description = "Specification of one or more ODEIO sites to serve";
    };

    user = mkOption {
      type = types.str;
      default = "odeio";
      description = "User to run the ODEIO service as";
    };

    builds = {
      directory = mkOption {
        type = types.path;
        default = "/var/lib/dei/odeio/builds";
        description = "Directory to store the ODEIO build artifacts";
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "SSH public keys authorized to do the deploy";
      };
    };
  };

  config = mkIf (sites != { }) {
    systemd.tmpfiles.rules =
      flatten (
        mapAttrsToList (_: siteCfg: [ "d ${siteCfg.stateDir} 0750 ${user} ${webserver.group} - -" ]) sites
      )
      ++ [
        "d /var/lib/dei/odeio 0750 ${user} ${webserver.group} - -"
        # TODO: use this - currently not working and things are still getting garbage-collected.
        # "L+ /nix/var/nix/gcroots/odeio-builds - - - - ${cfg.builds.directory}" # Adds ODEIO builds to gcroots so they aren't garbage collected
        "d ${cfg.builds.directory} 0750 ${user} ${webserver.group} - -"
      ];

    services.nginx = {
      enable = true;
      virtualHosts = mapAttrs' (_siteName: siteCfg: {
        name = siteCfg.serviceName;
        value = {
          serverName = mkDefault siteCfg.serverName;
          serverAliases = mkDefault siteCfg.serverAliases;
          root = "${siteCfg.stateDir}/www";
          enableACME = mkDefault true;
          forceSSL = mkDefault true;
          locations = {
            "/" = {
              tryFiles = "$uri $uri/ /index.html";
            };
          };
        };
      }) sites;
    };

    users.users = mkMerge [
      (mkIf (user == "odeio") {
        odeio = {
          isNormalUser = true;
          home = "/var/lib/dei/odeio";
          homeMode = "750";
          group = webserver.group;
          openssh.authorizedKeys.keys = cfg.builds.authorizedKeys;
        };
      })
      { root.packages = mapAttrsToList (_: siteCfg: siteCfg.deployScriptPackage) sites; }
    ];
  };
}
