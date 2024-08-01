{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.db-cluster;
  package = config.services.mysql.package;

  isMariaDB = getName package == getName pkgs.mariadb;

  userOptions = {
    name = mkOption {
      type = types.str;
      description = "Name of the user";
    };

    host = mkOption {
      type = types.str;
      description = "Host of the user";
      default = config.networking.fqdn;
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


      ${concatMapStrings (user: let
          authOption = optionalString (user.host == "localhost") "IDENTIFIED WITH ${
            if isMariaDB
            then "unix_socket"
            else "auth_socket"
          }";
        in ''
          ( echo "CREATE USER IF NOT EXISTS '${user.name}'@'${user.host}' ${authOption};"
            ${concatStringsSep "\n" (mapAttrsToList (database: permission: ''
              echo "GRANT ${permission} ON ${database} TO \`${user.name}\`@\`${user.host}\`;"
            '')
            user.ensurePermissions)}
          ) | ${package}/bin/mysql -N
        '')
        cfg.ensureUsers}
    '';

    environment.etc."mysql.state".text = let
      mkDatabase = database: "database:${database}";
      mkUser = user: "user:${user.name}@${user.host}:${mkPermissions user}";
      mkPermissions = user: lib.concatStringsSep ";" (mapAttrsToList (n: v: "${n}=${v}") user.ensurePermissions);
    in ''
      ${concatStringsSep "\n" (map mkDatabase cfg.ensureDatabases)}
      ${concatStringsSep "\n" (map mkUser cfg.ensureUsers)}
    '';

    environment.systemPackages = [pkgs.mysql-check-state];

    # TODO: Add a service to check if the user exists
    # and if there are databases, users or permissions dangling
  };
}
