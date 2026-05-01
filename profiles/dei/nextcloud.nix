{
  config,
  pkgs,
  lib,
  ...
}:
let
  ncPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        sha256 = "0szij1c0cl4xvjhzb0cwvskkl54dyw11skb9hgmnhamcmmsm6bji";
      })
      {
        system = pkgs.system;
        config.allowUnfree = true;
      };
in
{
  age.secrets.dei-nextcloud-secretFile = {
    file = ../../secrets/dei-nextcloud-secretFile.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/dei-nextcloud-secretFile";
  };

  age.secrets.dei-nextcloud-admin-pass = {
    file = ../../secrets/dei-nextcloud-admin-pass.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/dei-nextcloud-admin-pass";
  };

  age.secrets.dei-nextcloud-oidc = {
    file = ../../secrets/dei-nextcloud-oidc.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/dei-nextcloud-oidc";
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    serverName = "${config.services.nextcloud.hostName}";
    enableACME = true;
    forceSSL = true;
  };

  services.nginx.virtualHosts."${config.virtualisation.oci-containers.containers.collabora.environment.server_name
  }" =
    {
      serverName = "${config.virtualisation.oci-containers.containers.collabora.environment.server_name}";
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://[::1]:9980";
        proxyWebsockets = true;
      };
    };

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

    hostName = "drive.booble.rnl.tecnico.ulisboa.pt";

    maxUploadSize = "16G";
    https = true;

    autoUpdateApps = {
      enable = true;
      startAt = "05:00:00";
    };

    extraAppsEnable = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        groupfolders
        richdocuments
        user_oidc
        deck
        tasks
        calendar
        contacts
        files_automatedtagging
        spreed
        forms
        ;

      libresign = pkgs.fetchNextcloudApp {
        appName = "libresign";
        appVersion = "13.1.3";
        url = "https://github.com/LibreSign/libresign/releases/download/v13.1.3/libresign-v13.1.3.tar.gz";
        sha256 = "sha256-rjyCZX1+vEs2TmMGQs8hI3ty4DbMNH5tBggvhklttiQ=";
        license = "agpl3Plus";
      };

      fulltextsearch = pkgs.fetchNextcloudApp {
        appName = "fulltextsearch";
        appVersion = "33.0.0";
        url = "https://github.com/nextcloud-releases/fulltextsearch/releases/download/33.0.0/fulltextsearch-33.0.0.tar.gz";
        sha256 = "sha256-p7b+PA9z/KHB9ZRDDbO/y6CJFJLhH0xHEFc/rr1H6yg=";
        license = "agpl3Plus";
      };

      fulltextsearch_elasticsearch = pkgs.fetchNextcloudApp {
        appName = "fulltextsearch_elasticsearch";
        appVersion = "33.0.0";
        url = "https://github.com/nextcloud-releases/fulltextsearch_elasticsearch/releases/download/33.0.0/fulltextsearch_elasticsearch-33.0.0.tar.gz";
        sha256 = "sha256-Z0A8n2XqtFkS2XpvBGrjSuGS/lkGKGoJEiR0q7UEexE=";
        license = "agpl3Plus";
      };

      files_fulltextsearch = pkgs.fetchNextcloudApp {
        appName = "files_fulltextsearch";
        appVersion = "33.0.0";
        url = "https://github.com/nextcloud-releases/files_fulltextsearch/releases/download/33.0.0/files_fulltextsearch-33.0.0.tar.gz";
        sha256 = "sha256-5KaE6PSdDaxuEliFtr3zjnFNnRzUhsJU/8M7dvtUwEs=";
        license = "agpl3Plus";
      };

      flow = pkgs.fetchNextcloudApp {
        appName = "flow";
        appVersion = "1.3.0";
        url = "https://github.com/nextcloud-releases/flow/releases/download/v1.3.0/flow-v1.3.0.tar.gz";
        sha256 = "sha256-2KUyBb3Y1hnIRKBpaggVk09vBs+q+DlSoJAdDs+TQ18=";
        license = "agpl3Plus";
      };

    };

    settings = {
      overwriteProtocol = "https";

      default_phone_region = "PT";

      allow_local_remote_servers = true;

      loglevel = 2;
      log_type = "file";

      user_oidc = {
        auto_provision = true;
        soft_auto_provision = true;
        disable_account_creation = true;

        login_label = "Login via Fenix";
      };

    };

    database.createLocally = true;
    configureRedis = true;

    # This is just for the s3 settings atm
    secretFile = config.age.secrets.dei-nextcloud-secretFile.path;

    config = {
      dbtype = "pgsql";

      adminpassFile = config.age.secrets.dei-nextcloud-admin-pass.path;
      adminuser = "dei-admin";

      # S3 Object Storage for File Storage Backend
      objectstore.s3 = {
        enable = true;

        useSsl = false;
        usePathStyle = true;
        verify_bucket_exists = false;

        hostname = "193.136.164.35:7480";
        bucket = "nextcloud-bucket";
        secretFile = config.age.secrets.dei-nextcloud-secretFile.path; # will be replaced at runtime
        key = "placeholder"; # will be overwritten at runtime
      };
    };
  };

  virtualisation.oci-containers.containers.collabora = {
    image = "collabora/code:latest";

    environment = {
      aliasgroup1 = "https://${config.services.nextcloud.hostName}";
      server_name = "collabora.booble.rnl.tecnico.ulisboa.pt";

      DONT_GEN_SSL_CERT = "1";

      extra_params = "--o:ssl.enable=false --o:ssl.termination=true --o:net.listen=loopback";
    };

    extraOptions = [
      "--cap-add=MKNOD"
      "--network=host"
    ];
  };

  virtualisation.oci-containers.containers."elasticsearch" = {
    image = "docker.elastic.co/elasticsearch/elasticsearch:9.3.1";

    ports = [ "127.0.0.1:9200:9200" ];

    environment = {
      "discovery.type" = "single-node";
      "xpack.security.enabled" = "false";
      "ES_JAVA_OPTS" = "-Xms1g -Xmx8g";
    };

  };

  systemd.services.nextcloud-fulltext-live = {
    description = "Nextcloud Full Text Search Live Indexer";
    after = [
      "nextcloud-setup.service"
      "podman-elasticsearch.service"
      "postgresql.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ fulltextsearch:live --quiet";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  programs.nix-ld.enable = true;

  services.phpfpm.pools.nextcloud.phpEnv."PATH" = lib.mkForce (
    lib.makeBinPath (
      with pkgs;
      [
        poppler_utils
        openssl
        jre
        pdftk
        which
        perl
      ]
    )
    + ":/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin"
  );

  systemd.services.phpfpm-nextcloud.path = with pkgs; [
    jre
    pdftk
    openssl
  ];

  environment.systemPackages = with pkgs; [
    util-linux
  ];

}
