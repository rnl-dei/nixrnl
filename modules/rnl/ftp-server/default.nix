{
  config,
  lib,
  pkgs,
  # profiles,
  ...
}:
with lib;
let
  cfg = config.rnl.ftp-server;

  # inherit (config.security.acme) certs;

  mirrorOptions =
    {
      config,
      name,
      ...
    }:
    {
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
        target.path = mkOption {
          type = types.str;
          description = "Target to sync to";
        };
        target.create = mkOption {
          type = types.bool;
          description = "Create the folder of target";
          default = true;
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
          default = pkgs.rsync + "/bin/rsync"; # NOTE: Use lib.out?
        };
        args = mkOption {
          type = types.listOf types.str;
          description = "Arguments to pass to the script";
          default = [
            config.source
            config.target.path
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
          ]; # TODO: maybe not hardcode the times?
        };
        extraArgs = mkOption {
          type = types.listOf types.str;
          description = "Extra arguments to pass to the script";
          default = [ ];
        };
        extraServiceConfig = mkOption {
          type = types.attrs;
          description = "Extra service configuration";
          default = { };
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

  services = lib.mapAttrs' (name: value: {
    name = "rnl-mirror-${name}";
    value = attrsets.recursiveUpdate {
      description = "RNL mirror - ${value.mirrorName}";
      serviceConfig = {
        User = value.user;
        Group = value.group;
        Environment = ''"UNIT_NAME=rnl-mirror-${name}"'';
        SyslogIdentifier = ''"rnl-mirror-${name}"'';
      };
      startAt = value.timer;
      script = value.script;
    } value.extraServiceConfig;
  }) cfg.mirrors;

  tmpfilesRules = lib.mapAttrsToList (
    _: mirror:
    (
      if mirror.target.create then "d ${mirror.target.path} 0775 ${mirror.user} ${mirror.group}" else null
    )
  ) cfg.mirrors;
in
{
  options.rnl.ftp-server = {
    enable = mkEnableOption "FTP server";
    passivePorts = mkOption {
      type = types.listOf types.port;
      description = "Ports to allow passive access";
      default = (lib.lists.range 15000 15005);
    };
    rootDirectory = mkOption {
      type = types.str;
      description = "Directory to serve via rsync";
      default = "/mnt/data/ftp/pub";
    };
    motd = mkOption {
      type = types.str;
      description = "Message of the day to use";
      default = "/etc/motd";
    };
    enableFTP = mkOption {
      type = types.bool;
      description = "Enable FTP access to the mirror";
      default = true;
    };
    enableRsync = mkOption {
      type = types.bool;
      description = "Enable rsync access to the mirror";
      default = true;
    };
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
    users.groups.mirror = { };

    systemd.tmpfiles.rules = tmpfilesRules;

    services.rsyncd = {
      enable = cfg.enableRsync;
      settings = {
        global = {
          "motd file" = cfg.motd;
        };
        pub = {
          comment = "RNL FTP mirror";
          path = cfg.rootDirectory;

          "use chroot" = true;
          "read only" = true;
          "max connections" = 100;
          "uid" = "nobody";
          "gid" = "nobody";
          "transfer logging" = false;
          "log format" = "%t %a %m %f %b";

          "timeout" = 300;
        };
      };
    };

    services.vsftpd = {
      enable = cfg.enableFTP;
      anonymousUser = true;
      anonymousUserHome = cfg.rootDirectory;
      anonymousUserNoPassword = true;
      #rsaCertFile = "${certs.${config.networking.fqdn}.directory}/fullchain.pem";
      #rsaKeyFile = "${certs.${config.networking.fqdn}.directory}/key.pem";
      extraConfig = ''
        allow_anon_ssl=YES
        banner_file=${cfg.motd}
        pasv_enable=YES
        # this might not be the best way but find first given pred finds the first matching
        # so this way it just finds the first...
        pasv_min_port=${toString (lib.lists.findFirst (_: true) null cfg.passivePorts)}
        pasv_max_port=${toString (lib.lists.last cfg.passivePorts)}
      '';
    };

    networking.firewall.allowedTCPPorts =
      (lib.lists.optional cfg.enableRsync config.services.rsyncd.port)
      ++ (lib.lists.optional cfg.enableFTP 21 ++ cfg.passivePorts);
  };
}
