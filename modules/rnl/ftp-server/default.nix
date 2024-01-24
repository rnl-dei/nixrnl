{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.ftp-server;

  mirrorOptions = {
    config,
    name,
    ...
  }: {
    options = {
      mirrorName = mkOption {
        type = types.str;
        description = "Friendly name of the mirror";
        default = name;
      };
      source = mkOption {
        type = types.str;
        description = "Source to sync from";
      };
      target = mkOption {
        type = types.str;
        description = "Target to sync to";
      };
      timer = mkOption {
        type = types.either (types.listOf types.str) types.str;
        description = "Timer to use to sync the mirror (OnCalendar format)";
        default = "daily";
      };
      user = mkOption {
        type = types.str;
        description = "User to run the script as";
        default = cfg.user;
      };
      group = mkOption {
        type = types.str;
        description = "Group to run the script as";
        default = cfg.group;
      };
      command = mkOption {
        type = types.str;
        description = "Command to use to sync the mirror";
        default = pkgs.rsync + "/bin/rsync";
      };
      args = mkOption {
        type = types.listOf types.str;
        description = "Arguments to pass to the script";
        default = [
          config.source
          config.target
          "--stats"
          "--recursive"
          "--links"
          "--perms"
          "--times"
          "--delete-delay"
          "--delay-updates"
          "--safe-links"
          "--hard-links"
          "--timeout=800"
          "--contimeout=300"
          "--fuzzy"
          "--human-readable"
        ];
      };
      extraArgs = mkOption {
        type = types.listOf types.str;
        description = "Extra arguments to pass to the script";
        default = [];
      };
      script = mkOption {
        type = types.str;
        description = "Script to use to sync the mirror";
        default = ''
          ${config.command} ${toString config.args} ${toString config.extraArgs}
        '';
      };
    };
  };

  services =
    lib.mapAttrs' (name: value: {
      name = "rnl-mirror-${name}";
      value = {
        description = "RNL mirror - ${value.mirrorName}";
        serviceConfig = {
          User = value.user;
          Group = value.group;
        };
        startAt = value.timer;
        script = value.script;
      };
    })
    cfg.mirrors;
in {
  options.rnl.ftp-server = {
    enable = mkEnableOption "FTP server";
    user = mkOption {
      type = types.str;
      description = "User to run the script as";
      default = "mirror";
    };
    group = mkOption {
      type = types.str;
      description = "Group to run the script as";
      default = "mirror";
    };
    stateDir = mkOption {
      type = types.str;
      description = "State directory to use";
      default = "/var/lib/rnl-mirror";
    };
    mirrors = mkOption {
      type = types.attrsOf (types.submodule mirrorOptions);
    };
  };

  config = mkIf cfg.enable {
    systemd.services = services;

    users.users.mirror = {
      isSystemUser = true;
      group = "mirror";
      description = "RNL mirror user";
      home = cfg.stateDir;
    };
    users.groups.mirror = {};
  };
}
