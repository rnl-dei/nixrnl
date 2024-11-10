{ lib, pkgs, ... }:
let
  initialScript = pkgs.writeText "initial_script.sql" ''
    CREATE USER 'dms'@'%' IDENTIFIED WITH 'mysql_native_password' AS '*3B5A67F9EE58BFAC2CA7E73F52866320C738263C';
    -- Password generated with: SELECT PASSWORD('<password here>')
    GRANT ALL PRIVILEGES ON dms.* TO 'dms'@'%' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
  '';
in
{
  networking.firewall.enable = false; # make life easier for everyone

  systemd.services."mysql".serviceConfig = {
    # Container creation and population can take some time in slow VMs
    # Looking at you, blatta @ chapek
    TimeoutStartSec = lib.mkForce "10min 0s";
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb_106; # same as RNL db cluster, at time of writing
    #package = pkgs.mariadb;
    ensureDatabases = [ "dms" ];
    inherit initialScript;

    ensureUsers = [
      {
        name = "dms";
        ensurePermissions = {
          "dms.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
