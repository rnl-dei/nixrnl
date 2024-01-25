{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
with lib; let
  cfg = config.rnl.ftp-server;
  inherit (config.security.acme) certs;

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
  #imports = lists.optional cfg.enableFTP profiles.certicates or lists.optional cfg.enableHTTPS profiles.webserver;
  imports = [profiles.webserver];
  options.rnl.ftp-server = {
    enable = mkEnableOption "FTP server";
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
    enableHTTP = mkOption {
      type = types.bool;
      description = "Enable HTTP access to the mirror";
      default = true;
    };
    enableHTTPS = mkOption {
      type = types.bool;
      description = "Enable HTTPS access to the mirror";
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
    users.groups.mirror = {};

    services.rsyncd = {
      enable = cfg.enableRsync;
      settings = {
        pub = {
          comment = "RNL FTP mirror";
          path = cfg.rootDirectory;

          "use chroot" = true;
          "read only" = true;
          "max connections" = 100;
          "motd file" = cfg.motd;
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
      rsaCertFile = "${certs.${config.networking.fqdn}.directory}/fullchain.pem";
      rsaKeyFile = "${certs.${config.networking.fqdn}.directory}/key.pem";
      extraConfig = ''
        allow_anon_ssl=YES
        ftpd_banner=OLÄ AMIGOS E AMIGAS BEM VINDOS AO SERVIDOR DE FTP DA RNL!!!! ENJOY E CARRREGA NO SININHO!
      '';
    };

    services.nginx.virtualHosts.ftp = {
      serverName = lib.mkDefault "${config.networking.fqdn}";
      enableACME = true;
      forceSSL = true;
      locations = {
        "/pub/" = {
          alias = cfg.rootDirectory;
        };
      };
    };

    networking.firewall.allowedTCPPorts = (lib.lists.optional cfg.enableRsync config.services.rsyncd.port) ++ (lib.lists.optional cfg.enableFTP 21);
  };
}
