{
  config,
  lib,
  pkgs,
  nixosConfigurations,
  ...
}:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb_106;
    settings = {
      mysqld = {
        bind_address = "0.0.0.0";
        binlog_format = "ROW"; # Default option is MIXED and does not work with Galera

        # WSREP
        # Reference: https://galeracluster.com/library/documentation/mysql-wsrep-options.html
        wsrep_on = true;
        wsrep_cluster_address = "gcomm://db2,db1,db0";
        wsrep_cluster_name = "rnl_db_cluster";
        wsrep_node_name = config.networking.hostName;
        wsrep_notify_cmd = "${pkgs.wsrep-notify-script}/bin/wsrep-notify-script.sh --mailto robots@${config.rnl.domain}";
        wsrep_provider = "${pkgs.mariadb-galera}/lib/libgalera_smm.so";
      };
    };
  };

  rnl.db-cluster =
    let
      # Only consider hosts that have the db-cluster option disabled
      hosts = lib.filterAttrs (_: { config, ... }: !config.rnl.db-cluster.enable) nixosConfigurations;
      ensureDatabases = [ ] ++ config.services.mysql.ensureDatabases;
      ensureUsers = [
        {
          name = "root";
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ]
      ++ (map (u: u // { host = "localhost"; }) config.services.mysql.ensureUsers);
    in
    {
      enable = lib.mkForce true;
      ensureDatabases =
        ensureDatabases
        ++ lib.flatten (
          lib.mapAttrsToList (_: { config, ... }: config.rnl.db-cluster.ensureDatabases) hosts
        );
      ensureUsers =
        ensureUsers
        ++ lib.flatten (lib.mapAttrsToList (_: { config, ... }: config.rnl.db-cluster.ensureUsers) hosts);
    };

  # Required for WSREP scripts
  # Reference: https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/mysql/mariadb-galera.nix
  systemd.services.mysql.path = with pkgs; [
    bash
    gawk
    gnutar
    gzip
    inetutils
    iproute2
    netcat
    procps
    pv
    rsync
    socat
    stunnel
    which
  ];

  # Galera ports
  # Reference: https://galeracluster.com/library/documentation/firewall-settings.html
  networking.firewall = {
    allowedTCPPorts = [
      3306
      4567
      4568
      4444
    ];
    allowedUDPPorts = [ 4567 ];
  };

  networking.extraHosts = ''
    192.168.21.1 db1.${config.networking.domain}
    192.168.21.2 db2.${config.networking.domain}
  '';

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.db-clusterIP4 = {
      virtualRouterId = 95;
      interface = lib.mkDefault "eno1";
      virtualIps = [ { addr = "193.136.164.95/26"; } ]; # db IPv4
      trackScripts = [ "check_mysql" ];
    };

    vrrpScripts = {
      check_mysql = {
        user = config.services.mysql.user;
        interval = 2;
        script = "${config.services.mysql.package}/bin/mysqladmin ping";
      };
    };
  };

  # spellchecker:off
  users.motd = ''

    ################################################################################

      [1;31mRNL DB cluster [0m[2m--> https://weaver.rnl.tecnico.ulisboa.pt/dokuwiki/doku.php?id=servicos:db_cluster[0m

      * [0;31mRecuperação do cluster após falha de todos os nós:[0m
        Como os nós assumem por omissão que já existe um nó primário online,
          é preciso iniciar um dos nós como primário.
          1. [1;34mMonitorizar os logs em todos os nós: [0;36m'journalctl -u mysql -f &' [1;34m[0m
          2. [1;34mCorrer [0;36m'systemctl stop mysql' [1;34mem [4mtodos[24m os nós[0m
          3. [1;34mCorrer [0;36m'galera_new_cluster' [1;34mnum dos nós (de preferência o último que ficou offline)[0m
              (Vai falhar, segue os passos indicados nos logs)
          4. [1;34mCorrer [0;36m'systemctl start mysql' [1;34mnos restantes nós[0m

      * [0;31mVerificar estado do cluster:[0m
        $ [1;34mecho "SHOW STATUS LIKE 'wsrep_%';" | mysql -p[0m

    ################################################################################

  '';
  # spellchecker:on
}
