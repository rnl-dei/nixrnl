{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.githook;

  hookOptions = {
    config,
    name,
    ...
  }: {
    options = {
      url = mkOption {
        type = types.str;
        description = "URL to the git repository";
      };
      path = mkOption {
        type = types.str;
        default = "/var/lib/rnl/${name}";
        description = "The path to the local repository";
      };
      emailDestination = mkOption {
        type = types.str;
        default = cfg.emailDestination;
        description = "The email address to send the notification to";
      };
      secretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "The path to the secret file";
      };
      hookEndpoint = mkOption {
        type = types.str;
        default = name;
        description = "The endpoint to send the notification to";
      };
      hookScript = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          The path to the script that run when pull is done and changes are detected
          Default: Command in the root of the repository (.pull_hooks.sh)
        '';
      };
      user = mkOption {
        type = types.str;
        default = "root";
        description = "The user to run the hook as";
      };
      directoryMode = mkOption {
        type = types.str;
        default = "0750";
        description = "The mode of the directory";
      };
      directoryUser = mkOption {
        type = types.str;
        default = "root";
        description = "The user to own the directory";
      };
      directoryGroup = mkOption {
        type = types.str;
        default = config.directoryUser;
        description = "The group to own the directory";
      };
      hookCommand = mkOption {
        type = types.str;
        default = "${pkgs.pull-repo}/bin/pull-repo ${config.url} ${config.path} ${config.emailDestination} ${toString config.hookScript}";
        description = "The command to run when the hook is triggered";
      };
    };
  };
in {
  options.rnl.githook = {
    enable = mkEnableOption "Enable git hooks";
    port = mkOption {
      type = types.int;
      default = 9000;
      description = "Port to listen on";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall for the port";
    };
    emailDestination = mkOption {
      type = types.str;
      default = "robots@localhost";
      description = "The email address to send the notification to";
    };
    urlPrefix = mkOption {
      type = types.str;
      default = "hooks";
      description = "URL prefix for the webhook";
    };
    hooks = mkOption {
      type = types.attrsOf (types.submodule hookOptions);
      default = {};
      description = "Set of hooks to be called on events";
    };
    user = mkOption {
      type = types.str;
      default = "root";
      description = "The user to run the server as";
    };
    group = mkOption {
      type = types.str;
      default = "root";
      description = "The group to run the server as";
    };
  };

  config = mkIf cfg.enable {
    services.webhook = {
      enable = true;
      enableTemplates = true;
      port = cfg.port;
      openFirewall = cfg.openFirewall;
      urlPrefix = cfg.urlPrefix;
      user = cfg.user;
      group = cfg.group;
      hooks =
        attrsets.mapAttrs' (name: hook: {
          name = hook.hookEndpoint;
          value = {
            execute-command = "${pkgs.su}/bin/su";
            pass-arguments-to-command = [
              {
                source = "string";
                name = "${hook.user}";
              }
              {
                source = "string";
                name = "-c";
              }
              {
                source = "string";
                name = "${hook.hookCommand}";
              }
            ];
            command-working-directory = hook.path;
            response-message = "Hook executed";
            trigger-rule = mkIf (hook.secretFile != null) {
              match = {
                type = "value";
                value = "{{ file.Read ${hook.secretFile} }}";
                parameter = {
                  source = "header";
                  name = "X-Gitlab-Token";
                };
              };
            };
          };
        })
        cfg.hooks;
    };

    systemd.tmpfiles.rules = attrsets.mapAttrsToList (_name: hook: "d ${hook.path} ${hook.directoryMode} ${hook.directoryUser} ${hook.directoryGroup} - -") cfg.hooks;
  };
}
