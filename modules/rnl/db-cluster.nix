{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.rnl.db-cluster;
  package = config.services.mysql.package;

  userOptions = {
    name = mkOption {
      type = types.str;
      description = "Name of the user";
    };

    host = mkOption {
      type = types.str;
      description = "Host of the user";
      default = "localhost";
    };

    ensurePermissions = mkOption {
      type = types.attrsOf types.str;
      description = "List of permissions for the user";
      default = {};
    };
  };
in {
  options.rnl.db-cluster = {
    enable = mkEnableOption "Enable DB Cluster server configuration";

    ensureDatabases = mkOption {
      type = types.listOf types.str;
      description = "List of databases to be created";
      default = [];
    };

    ensureUsers = mkOption {
      type = types.listOf (types.submodule {options = userOptions;});
      description = "List of users to be created";
      default = [];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.mysql.postStart = lib.mkForce ''
      # Wait until the MySQL socket is ready
      while [ ! -e /run/mysqld/mysqld.sock ]; do
        echo "MySQL daemon not yet started. Waiting for 1 second..."
        sleep 1
      done

      # Wait until WSREP is synced
      while ! ${package}/bin/mysql -e "SHOW STATUS LIKE 'wsrep_local_state_comment'" | grep -q 'Synced'; do
        echo "WSREP not yet synced. Waiting for 1 second..."
        sleep 1
      done

      # Wait until WSREP is ready
      while ! ${package}/bin/mysql -e "SHOW STATUS LIKE 'wsrep_ready'" | grep -q 'ON'; do
        echo "WSREP not yet ready. Waiting for 1 second..."
        sleep 1
      done

      ${optionalString (cfg.ensureDatabases != []) ''
        (
        ${concatMapStrings (database: ''
            echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
          '')
          cfg.ensureDatabases}
        ) | ${package}/bin/mysql -N
      ''}
    '';

    # TODO: Add a service to check if the user exists
    # and if there are databases, users or permissions dangling
  };
}
