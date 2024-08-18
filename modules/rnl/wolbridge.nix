{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.wolbridge;
  defaultUser = "wolbridge";
  location = "/var/lib/wolbridge";
  defaultStateFile = "${location}/state.json";
in {
  options.rnl.wolbridge = {
    enable = mkEnableOption "Enable the WoL-Bridge service.";

    package = mkOption {
      type = types.package;
      default = pkgs.wolbridge;
      description = "The WoL-Bridge package to use.";
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "The user to run the WoL-Bridge service as.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "The host to listen on.";
    };

    port = mkOption {
      type = types.int;
      default = 8099;
      description = "The port to listen on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the WoL-Bridge service.";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The domain to use for the WoL-Bridge service.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The file to store the configuration of the WoL-Bridge service.";
    };

    stateFile = mkOption {
      type = types.nullOr types.path;
      default = defaultStateFile;
      description = "The file to store the state of the WoL-Bridge service.";
    };

    updateInterval = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "The interval in seconds to update the state of the WoL-Bridge service.";
    };

    pingSchedule = mkOption {
      type = types.str;
      default = "*-*-* */3:00:00";
      description = "The schedule to ping the devices.";
    };

    pingHosts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "The hosts to ping.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = optionals cfg.openFirewall [cfg.port];

    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        isSystemUser = true;
        createHome = false;
        group = "nogroup";
      };
    };

    systemd.services.wolbridge = {
      description = "Wake-on-LAN Bridge";
      after = ["netservcieswork.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOST = cfg.host;
        PORT = "${toString cfg.port}";
      };
      serviceConfig = {
        User = cfg.user;
        KillSignal = "SIGINT";
        ExecStart =
          "${cfg.package}/bin/wolbridge"
          + (optionalString (cfg.domain != null) " --domain ${cfg.domain}")
          + (optionalString (cfg.configFile != null) " --config ${cfg.configFile}")
          + (optionalString (cfg.stateFile != null) " --state-file ${cfg.stateFile}")
          + (optionalString (cfg.updateInterval != null) " --update-interval ${toString cfg.updateInterval}");
      };
    };

    systemd.services.wolbridge-scan = mkIf (cfg.pingHosts != []) {
      description = "Wake-on-LAN Bridge scan hosts to learn MAC addresses";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
      };
      script = ''
        for host in ${lib.concatStringsSep " " cfg.pingHosts}; do
          echo "Pinging $host";
          ${pkgs.unixtools.ping}/bin/ping -W 1 -c 1 $host || true &> /dev/null &
        done
      '';
    };

    systemd.timers.wolbridge-scan = mkIf (cfg.pingHosts != []) {
      description = "Wake-on-LAN Bridge scan timer";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.pingSchedule;
        AccuracySec = "5m";
        Unit = "wolbridge-scan.service";
      };
    };

    systemd.tmpfiles.rules = optionals (cfg.stateFile == defaultStateFile) [
      "d ${location} 0755 ${cfg.user} - - -"
    ];
  };
}
