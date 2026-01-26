{
  config,
  pkgs,
  ...
}:
{
  age.secrets.dei-nextcloud-secretFile = {
    file = ../../secrets/dei-nextcloud-secretFile.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/dei-nextcloud-secretFile";
  };

  age.secrets.dei-nextcloud-admin-pass = {
    file = ../../secrets/dei-nextcloud-admin-pass.age;
    owner = "nextcloud";
    path = "/var/lib/onlyoffice/dei-nextcloud-admin-pass";
  };

  age.secrets.dei-onlyoffice-jwt = {
    file = ../../secrets/dei-onlyoffice-jwt.age;
    owner = "onlyoffice";
    group = "nextcloud"; # to allow Nextcloud to read the JWT secret
    mode = "440"; # read for owner and group only
    path = "/var/lib/onlyoffice/dei-onlyoffice-jwt";
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

  services.nginx.virtualHosts."${config.services.onlyoffice.hostname}" = {
    serverName = "${config.services.onlyoffice.hostname}";
    enableACME = true;
    forceSSL = true;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;

    hostName = "drive.dei.tecnico.ulisboa.pt";

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
        onlyoffice
        user_oidc
        deck
        #mail
        tasks
        calendar
        contacts
        files_automatedtagging
        ;

      libresign = pkgs.fetchNextcloudApp {
        appName = "libresign";
        appVersion = "11.6.0";
        url = "https://github.com/LibreSign/libresign/releases/download/v11.6.0/libresign-v11.6.0.tar.gz";
        sha256 = "ddae9486fe7a69ab79632542bf60add20ce985c41c76803f505d31e501c5229c";
        license = "agpl3Plus";
      };

      fulltextsearch = pkgs.fetchNextcloudApp {
        appName = "fulltextsearch";
        appVersion = "31.0.1";
        url = "https://github.com/nextcloud-releases/fulltextsearch/releases/download/31.0.1/fulltextsearch-31.0.1.tar.gz";
        sha256 = "sha256-8kSSFo2rdWIsL25qn6DfSdUqCCXCXMy1o0IcIXLKPJ8=";
        license = "agpl3Plus";
      };

      fulltextsearch_elasticsearch = pkgs.fetchNextcloudApp {
        appName = "fulltextsearch_elasticsearch";
        appVersion = "31.0.2";
        url = "https://github.com/nextcloud-releases/fulltextsearch_elasticsearch/releases/download/31.0.2/fulltextsearch_elasticsearch-31.0.2.tar.gz";
        sha256 = "sha256-x+OkbLLRb0GMCqPT4+PQsEXMDkaLqW0+q0WoXRqNqN0=";
        license = "agpl3Plus";
      };

      files_fulltextsearch = pkgs.fetchNextcloudApp {
        appName = "files_fulltextsearch";
        appVersion = "31.0.0";
        url = "https://github.com/nextcloud-releases/files_fulltextsearch/releases/download/31.0.0/files_fulltextsearch-31.0.0.tar.gz";
        sha256 = "sha256-gfe7FnGR7qxfUOQr/ZjPNikIWL06WzTp5tjdyLknapE=";
        license = "agpl3Plus";
      };

    };

    settings = {
      overwriteProtocol = "https";

      default_phone_region = "PT";

      allow_local_remote_servers = true;

      onlyoffice = {
        DocumentServerUrl = "https://${config.services.onlyoffice.hostname}/";

        jwt_header = "Authorization";

        verify_peer_off = true;
      };

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

        useSsl = true;
        region = "garage";
        usePathStyle = true;

        hostname = "${config.services.garage.settings.s3_api.root_domain}";
        bucket = "nextcloud-bucket";
        secretFile = config.age.secrets.dei-nextcloud-secretFile.path; # will be replaced at runtime
        key = "placeholder"; # will be overwritten at runtime
      };
    };
  };

  # There are some settings that are not possible to set via the Nextcloud config,
  # so we create a systemd service that runs once after Nextcloud setup to apply them
  # all this to have an "declarative" configuration via Nix
  systemd.services.nextcloud-runtime-config = {
    description = "Nextcloud runtime settings (OIDC & OnlyOffice)";
    after = [ "nextcloud-setup.service" ];
    requires = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    script =
      let
        nextcloudOcc = "${config.services.nextcloud.occ}/bin/nextcloud-occ";

        # OIDC stuff
        providerId = "Fenix";
        discoveryUrl = "https://gitlab.rnl.tecnico.ulisboa.pt/.well-known/openid-configuration";
      in
      ''
        # Configure OIDC provider
        source ${config.age.secrets.dei-nextcloud-oidc.path}

        ${nextcloudOcc} user_oidc:provider ${providerId} \
          --clientid="$OIDC_CLIENT_ID" \
          --clientsecret="$OIDC_CLIENT_SECRET" \
          --discoveryuri="${discoveryUrl}" \
          --scope="openid email profile" \
          --mapping-uid="nickname"



        # Configure OnlyOffice JWT secret
        OO_SECRET=$(cat ${config.age.secrets.dei-onlyoffice-jwt.path})

        ${nextcloudOcc} config:app:set onlyoffice jwt_secret --value="$OO_SECRET"
      '';
  };

  services.onlyoffice = {
    enable = true;
    hostname = "onlyoffice.dei.rnl.tecnico.ulisboa.pt";

    jwtSecretFile = config.age.secrets.dei-onlyoffice-jwt.path;
  };

  fileSystems."/var/lib/elasticsearch" = {
    device = "/mnt/data/elasticsearch";
    options = [ "bind" ];
  };

  services.elasticsearch = {
    enable = true;
    package = pkgs.elasticsearch7; # Nextcloud works best with ES 7.x or 8.x

    plugins = [ pkgs.elasticsearchPlugins.ingest-attachment ];

    # Listen only on localhost for security
    listenAddress = "127.0.0.1";
    port = 9200;

    # Limit memory usage (Adjust Xms and Xmx based on your available RAM)
    # 1g is usually enough for personal/small team use.
    extraJavaOptions = [
      "-Xms1g"
      "-Xmx1g"
    ];
  };

  systemd.services.phpfpm-nextcloud.path = with pkgs; [
    # for elasticsearch:
    perl
    which
    poppler_utils # pdftotext
    tesseract # OCR
    catdoc # .doc
    gawk
    gnugrep

    # for libresign:
    jdk17_headless
    pdftk
    openssl
  ];
}
