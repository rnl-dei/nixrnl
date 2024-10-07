{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rnl.mysqlBackup;
  defaultUser = "mysqlbackup";
  mysqlPkg = config.services.mysql.package or pkgs.mariadb;

  backupScript = ''
    set -o pipefail
    failed=""
    timestamp=$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S)
    destinationDir="${cfg.location}/$timestamp"
    ${concatMapStringsSep "\n" backupDatabaseScript cfg.databases}
    ${optionalString cfg.deleteOldBackups deleteOldBackupsScript}
    if [ -n "$failed" ]; then
      echo "Backup of database(s) failed:$failed"
      exit 1
    fi
  '';
  backupDatabaseScript = db: ''
    if [ ! -d "$destinationDir" ]; then
      mkdir -p "$destinationDir"
    fi
    dest="$destinationDir/${db}.gz"
    if ${mysqlPkg}/bin/mysqldump ${concatStringsSep " " cfg.arguments} ${db} | ${pkgs.gzip}/bin/gzip -c > $dest.tmp; then
      mv $dest.tmp $dest
      echo "Backed up to $dest"
    else
      echo "Failed to back up to $dest"
      rm -f $dest.tmp
      failed="$failed ${db}"
    fi
  '';
  deleteOldBackupsScript = ''
    find ${cfg.location} -type f -name '*.gz' -mtime +${toString cfg.retentionDays} -delete
    rmdir ${cfg.location}/* 2>/dev/null || true
  '';
in
{
  options.rnl.mysqlBackup = {
    enable = mkEnableOption "MySQL backups";

    calendar = mkOption {
      type = types.str;
      default = "01:15:00";
      description = ''
        Configured when to run the backup service systemd unit (DayOfWeek Year-Month-Day Hour:Minute:Second).
      '';
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = ''
        User to be used to perform backup.
      '';
    };

    databases = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = ''
        List of database names to dump.
      '';
    };

    location = mkOption {
      type = types.path;
      default = "/var/backup/mysql";
      description = ''
        Location to put the gzipped MySQL database dumps.
      '';
    };

    arguments = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Arguments to pass to mysqldump.
      '';
    };

    retentionDays = mkOption {
      type = types.int;
      default = 3;
      description = ''
        Number of days to keep the backups.
      '';
    };

    deleteOldBackups = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to delete old backups.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        isSystemUser = true;
        createHome = false;
        home = cfg.location;
        group = "nogroup";
      };
    };

    services.mysql.ensureUsers = [
      {
        name = cfg.user;
        ensurePermissions =
          let
            privs = "SELECT, SHOW VIEW, TRIGGER, LOCK TABLES";
            grant = db: nameValuePair "${db}.*" privs;
          in
          listToAttrs (map grant cfg.databases);
      }
    ];

    systemd = {
      timers.mysql-backup = {
        description = "Mysql backup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.calendar;
          AccuracySec = "5m";
          Unit = "mysql-backup.service";
        };
      };
      services.mysql-backup = {
        description = "MySQL backup service";
        enable = true;
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
        };
        script = backupScript;
      };
      tmpfiles.rules = [ "d ${cfg.location} 0700 ${cfg.user} - - -" ];
    };
  };
}
