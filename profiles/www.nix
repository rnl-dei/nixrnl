{
  config,
  lib,
  pkgs,
  profiles,
  ...
}: let
  rnlWebsitePort = 3000;
  # labsMatrixPort = 3001;
  opensessionsPort = 3002;
  # shortenerPort = 3002;

  nginxAllowRNLAdmin = ''
    # Rede admin
    allow 193.136.164.192/27;
    allow 2001:690:2100:82::/64;
  '';

  nginxAllowRNLLabs = ''
    # Rede LABs
    allow 193.136.154.0/25;
    allow 2001:690:2100:84::/64;
  '';
in {
  imports = with profiles; [
    webserver
    phpfpm
    containers.docker
  ];

  services.nginx.virtualHosts = {
    "www" = {
      serverName = config.rnl.domain;
      enableACME = true;
      forceSSL = true;
      locations = {
        "/".proxyPass = "http://localhost:${toString rnlWebsitePort}";
        "/dashboard".index = "index.html";
        "/logsession" = {
          proxyPass = "http://localhost.:${toString opensessionsPort}";
          extraConfig = ''
            ${nginxAllowRNLAdmin}
            ${nginxAllowRNLLabs}
            deny all;
          '';
        };
        "~ ^/tv([^\\r\\n]*)$".return = "301 https://tv.${config.rnl.domain}$1$is_args$args";
        "~ ^/labs-matrix([^\\r\\n]*)$".return = "301 https://labs-matrix.${config.rnl.domain}$1$is_args$args";
        "~ ^/(webmail|roundcube)([^\\r\\n]*)$".return = "301 https://webmail.${config.rnl.domain}$2$is_args$args";
        "~ ^/forum([^\\r\\n]*)$".return = "301 https://forum.${config.rnl.domain}$1$is_args$args";
      };
    };

    "webmail".serverName = "webmail.${config.rnl.domain}";
    "welcome" = {
      serverName = "welcome.${config.rnl.domain}";
      enableACME = true;
      forceSSL = true;
      locations."/".return = "301 https://${config.services.nginx.virtualHosts.www.serverName}";
    };
    "labs-matrix" = {
      serverName = "labs-matrix.${config.rnl.domain}";
      enableACME = true;
      forceSSL = true;
      root = pkgs.writeTextDir "index.html" ''
        <h1>Work in progress</h1>
      '';
      locations."/".index = "index.html";
    };
    # Redirect domains
    "www-redirect" = {
      serverName = "rnl.ist.utl.pt";
      serverAliases = ["www.${config.rnl.domain}" "www.rnl.ist.utl.pt"];
      enableACME = true;
      addSSL = true;
      locations."/".return = "301 https://${config.services.nginx.virtualHosts.www.serverName}";
      locations."~ ^/forum([^\\r\\n]*)$".return = "301 https://forum.${config.rnl.domain}$1$is_args$args";
    };
    "forum-redirect" = {
      serverName = "forum.rnl.ist.utl.pt";
      serverAliases = ["forum.ist.utl.pt" "forum.tecnico.ulisboa.pt"];
      enableACME = true;
      addSSL = true;
      locations."/".return = "301 https://${config.services.nginx.virtualHosts.forum.serverName}";
    };
    "webmail-redirect" = {
      serverName = "webmail.rnl.ist.utl.pt";
      enableACME = true;
      addSSL = true;
      locations."/".return = "301 https://${config.services.nginx.virtualHosts.webmail.serverName}";
    };
  };

  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = ["/var/run/docker.sock:/var/run/docker.sock"];
    environment = {
      "WATCHTOWER_LABEL_ENABLE" = "true"; # Filter containers by label "com.centurylinklabs.watchtower.enable"
      "WATCHTOWER_POLL_INTERVAL" = "300"; # 5 minutes
    };
  };

  virtualisation.oci-containers.containers."rnl-website" = {
    image = "registry.rnl.tecnico.ulisboa.pt/rnl/website:latest";
    ports = ["${toString rnlWebsitePort}:80"];
    labels = {
      "com.centurylinklabs.watchtower.enable" = "true";
    };
  };

  # TODO: Use new version of opensessions
  # virtualisation.oci-containers.containers."opensessions" = {
  #   image = "registry.rnl.tecnico.ulisboa.pt/rnl/opensessions:latest";
  #   ports = ["${toString opensessionsPort}:5000"];
  #   labels = {
  #     "com.centurylinklabs.watchtower.enable" = "true";
  #   };
  # };

  # TODO: Move Shortener from kutt to here
  # virtualisation.oci-containers.containers."shortener" = {
  #   image = "registry.rnl.tecnico.ulisboa.pt/rnl/shortener:latest";
  #   ports = ["${toString shortenerPort}:80"];
  # };

  # # Webmail RNL
  services.roundcube = {
    enable = true;
    hostName = "webmail";
    database = {
      dbname = "roundcube";
      username = "roundcube";
      passwordFile = config.age.secrets."roundcube-www-db.password".path;
      host = config.rnl.database.host;
    };
    plugins = ["archive" "zipdownload"];
    extraConfig = let
      # Fix for roundcube to work with MySQL since default is PostgreSQL
      # Reference: https://github.com/NixOS/nixpkgs/blob/25e3d4c0d3591c99929b1ec07883177f6ea70c9d/nixos/modules/services/mail/roundcube.nix#L140
      inherit (config.services.roundcube.database) username host dbname;
      databseURL = "mysql://${username}:' . $password . '@${host}/${dbname}";
    in ''
      $config['db_dsnw'] = '${databseURL}';
      $config['default_host'] = 'ssl://${config.rnl.mailserver.host}';
      $config['default_port'] = 993;
      $config['smtp_server'] = 'tls://${config.rnl.mailserver.host}';
      $config['smtp_port'] = 25;
      $config['product_name'] = 'RNL Webmail';
      $config['mail_domain'] = '${config.rnl.domain}';
      $config['cipher_method'] = 'AES-256-CBC';
    '';
  };
  # Change setup script since we are using MySQL
  # Reference: https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/mail/roundcube.nix
  systemd.services.roundcube-setup.script = let
    cfg = config.services.roundcube;
    inherit (cfg.database) username host dbname;
    passwordFile = cfg.database.passwordFile;

    mysql = "${pkgs.mariadb}/bin/mysql -N -h ${host} -u ${username} -p`cat ${passwordFile}` ${dbname}";
    php = config.services.phpfpm.pools.roundcube.phpPackage;
  in
    lib.mkForce ''
      version="$(${mysql} -e "SELECT value FROM system WHERE name = 'roundcube-version';" || true)"
      if ! (grep -E '[a-zA-Z0-9]' <<< "$version"); then
        ${mysql} < ${cfg.package}/SQL/mysql.initial.sql
      fi

      if [ ! -f /var/lib/roundcube/des_key ]; then
          base64 /dev/urandom | head -c 24 > /var/lib/roundcube/des_key;
          # we need to log out everyone in case change the des_key
          # from the default when upgrading from nixos 19.09
          ${mysql} -e 'TRUNCATE TABLE session;'
        fi

        ${php}/bin/php ${cfg.package}/bin/update.sh
    '';
  age.secrets."roundcube-www-db.password" = {
    file = ../secrets/roundcube-www-db-password.age;
    owner = config.services.phpfpm.pools.roundcube.user;
    mode = "0400";
  };

  # Opensessions
  services.nginx.virtualHosts."opensessions" = {
    serverName = "opensessions.${config.rnl.domain}";
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://localhost:${toString opensessionsPort}";
    extraConfig = ''
      ${nginxAllowRNLAdmin}
      deny all;
    '';
  };

  # Forum
  services.nginx.virtualHosts."forum" = {
    serverName = "forum.${config.rnl.domain}";
    enableACME = true;
    forceSSL = true;
    root = "/var/www/forum";
    locations."/" = {
      index = "index.php";
    };
    locations."~* \\.php(/|$)" = {
      extraConfig = ''
        fastcgi_pass unix:${config.services.phpfpm.pools.forum.socket};
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        include ${config.services.nginx.package}/conf/fastcgi.conf;
      '';
    };
  };
  services.phpfpm.pools."forum" = {
    user = "nobody";
    phpPackage = pkgs.php83;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "listen.group" = config.services.nginx.group;
      "listen.mode" = "0660";
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
  };
  rnl.db-cluster = let
    roundcube = {
      database = config.services.roundcube.database.dbname;
      username = config.services.roundcube.database.username;
    };
    tv-cms = {
      database = config.virtualisation.oci-containers.containers."tv-cms".environment.DATABASE_NAME;
      username = config.virtualisation.oci-containers.containers."tv-cms".environment.DATABASE_USERNAME;
    };
  in {
    ensureDatabases = [
      "forum_rnl"
      "opensessions"
      roundcube.database
      tv-cms.database
    ];
    ensureUsers = [
      {
        name = "forum_user";
        ensurePermissions = {
          "forum_rnl.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "opensessions";
        ensurePermissions = {
          "opensessions.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = roundcube.username;
        ensurePermissions = {
          "${roundcube.database}.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "satellite";
        ensurePermissions = {
          "tv_contents_strapi.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # users.users.forum = {
  #   isSystemUser = true;
  #   createHome = false;
  #   group = "forum";
  # };
  # users.groups.forum = {};

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.wwwIP4 = {
      virtualRouterId = 8;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "193.136.164.8/26";}]; # www IPv4
    };
    vrrpInstances.wwwIP6 = {
      virtualRouterId = 8;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "2001:690:2100:80::8/64";}]; # www IPv6
    };
  };
}
