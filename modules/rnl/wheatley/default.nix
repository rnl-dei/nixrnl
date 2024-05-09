{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.wheatley;

  instanceOptions = {
    config,
    name,
    ...
  }: {
    options = {
      name = mkOption {
        type = types.str;
        default =
          if name == "default"
          then "wheatley"
          else "wheatley-${name}";
        description = "The name of the Wheatley instance.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.wheatley;
        description = "The package to use for Wheatley.";
      };

      mattermost = {
        url = mkOption {
          type = types.str;
          example = "https://mattermost.example.com";
          description = "The URL of the Mattermost server to connect to.";
        };
        tokenFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/var/lib/wheatley/mattermost-token";
          description = ''
            The path to the file containing the Mattermost token.
            If not set, the token must be provided in the environment (MATTERMOST_TOKEN)
            or in configuration file (mattermost.token).
          '';
        };
      };

      config = mkOption {
        type = types.lines;
        description = ''
          Configuration for the Wheatley instance.
          This is ignored if `configFile` is set.
        '';
      };

      configFile = mkOption {
        type = types.path;
        default = pkgs.writeText "wheatley-config" config.config;
        description = "The path to the Wheatley configuration file.";
      };

      command = mkOption {
        type = types.str;
        default = "${config.package}/bin/wheatley --config ${config.configFile}";
        description = "The command to run Wheatley.";
      };
    };
  };
in {
  options.rnl.wheatley = {
    enable = mkEnableOption "Wheatley, the RNL's Mattermost bot";

    user = mkOption {
      type = types.str;
      default = "wheatley";
      description = "The user to run Wheatley as.";
    };

    group = mkOption {
      type = types.str;
      default = "wheatley";
      description = "The group to run Wheatley as.";
    };

    instances = mkOption {
      type = types.attrsOf (types.submodule instanceOptions);
      default = {};
      description = "Configuration for Wheatley instances.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services =
      mapAttrs' (name: instanceCfg: {
        name = instanceCfg.name;
        value = {
          description = "Wheatley Bot instance ${name}";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];

          environment.MATTERMOST_URL = instanceCfg.mattermost.url;

          script =
            (optionalString (instanceCfg.mattermost.tokenFile != null) ''
              export MATTERMOST_TOKEN=$(cat ${instanceCfg.mattermost.tokenFile})
            '')
            + ''
              exec ${instanceCfg.command}
            '';

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10s";
            StartLimitBurst = "3";
            User = cfg.user;
            Group = cfg.group;
          };
        };
      })
      cfg.instances;

    users.users = mkIf (cfg.user == "wheatley") {
      wheatley = {
        isSystemUser = true;
        group = cfg.group;
      };
    };
    users.groups = mkIf (cfg.group == "wheatley") {
      wheatley = {};
    };
  };
}
