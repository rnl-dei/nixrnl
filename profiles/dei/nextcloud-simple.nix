{
  config,
  pkgs,
  ...
}:

let
  ncPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        sha256 = "1p54fm6dkbq62kpi55cr4wyx7b1nsajpsnjgs64cmp073fwi15f7";
      })
      {
        system = pkgs.system;
        config.allowUnfree = true;
      };

  hostAddr = "192.168.100.10";
  ctAddr = "192.168.100.11";
in
{
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp1s0";
  };

  services.nginx.virtualHosts."${config.containers.atas.config.services.nextcloud.hostName}" = {
    serverName = "${config.containers.atas.config.services.nextcloud.hostName}";
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      client_max_body_size 16G;
      proxy_request_buffering off;
    '';
    locations."/" = {
      proxyPass = "http://${ctAddr}:80";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        client_max_body_size 16G;
      '';
    };
  };

  containers.atas = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = hostAddr;
    localAddress = ctAddr;

    bindMounts = {
      "/run/atas-secrets/admin-pass" = {
        hostPath = config.age.secrets.dei-nextcloud-admin-pass.path;
        isReadOnly = true;
      };
      "/run/atas-secrets/secretfile.json" = {
        hostPath = config.age.secrets.dei-nextcloud-secretFile.path;
        isReadOnly = true;
      };
    };

    config =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        services.nextcloud = {
          enable = true;
          package =
            let
              base = ncPkgs.nextcloud33;
            in
            base
            // {
              override = args: base.override (builtins.removeAttrs args [ "caBundle" ]);
            };
          hostName = "docs.dei.tecnico.ulisboa.pt";
          https = true;
          maxUploadSize = "16G";

          database.createLocally = true;
          configureRedis = true;

          secretFile = "/run/atas-secrets/secretfile.json";

          settings = {
            overwriteprotocol = "https";
            overwritehost = "docs.dei.tecnico.ulisboa.pt";
            "overwrite.cli.url" = "https://docs.dei.tecnico.ulisboa.pt/";
            trusted_proxies = [ hostAddr ];
            default_phone_region = "PT";
            allow_local_remote_servers = true;
            loglevel = 2;
            log_type = "file";

            "social_login_auto_redirect" = true;
          };

          config = {
            dbtype = "pgsql";
            adminpassFile = "/run/atas-secrets/admin-pass";
            adminuser = "dei-admin";
            objectstore.s3 = {
              enable = true;
              useSsl = false;
              usePathStyle = true;
              verify_bucket_exists = false;
              hostname = "193.136.164.35:7480";
              bucket = "nextcloud-bucket-simple";
              secretFile = "/run/atas-secrets/secretfile.json";
              key = "placeholder";
            };
          };

          extraAppsEnable = true;

          extraApps = {
            inherit (config.services.nextcloud.package.packages.apps)
              groupfolders
              ;

            sociallogin = pkgs.fetchNextcloudApp {
              # use fork of sociallogin to try and step over their implementation incompatibilities
              appName = "sociallogin";
              appVersion = "6.4.2";
              url = "https://gitlab.rnl.tecnico.ulisboa.pt/rnl/nextcloud-social-login/-/archive/6.4.2/nextcloud-social-login-6.4.2.tar.bz2";
              sha256 = "sha256-JHq78AOL5rYI2fcM5R9CWN+8bGj+dKSdjDMIaQBV+Hw=";
              license = "agpl3Plus";
            };

            group_default_quota = pkgs.fetchNextcloudApp {
              appName = "group_default_quota";
              appVersion = "0.1.14";
              url = "https://github.com/icewind1991/group_default_quota/releases/download/v0.1.14/group_default_quota-v0.1.14.tar.gz";
              sha256 = "sha256-mSmiQhmhTbuNchv1RF6rbxwZAUhYr22z5fCsGA9fh0E=";
              license = "agpl3Plus";
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 80 ];

        networking.useHostResolvConf = lib.mkForce false;
        services.resolved.enable = true;

        system.stateVersion = "25.05";
      };
  };
}
