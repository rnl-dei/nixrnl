{
  config,
  pkgs,
  ...
}:
let
  unstableTarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    sha256 = "1vq77hlx8mi3z03pw2nf6r5h7473r1p9yxyf58ym3fh01zppmfln";
  };
  ncPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        sha256 = "1vq77hlx8mi3z03pw2nf6r5h7473r1p9yxyf58ym3fh01zppmfln";
      })
      {
        system = pkgs.system;
        config.allowUnfree = true;
      };
in
{
  imports = [
    "${unstableTarball}/nixos/modules/services/networking/nextcloud-spreed-signaling.nix"
  ];

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

  age.secrets.dei-spreed-backend-secret = {
    file = ../../secrets/dei-spreed-backend-secret.age;
    owner = "nextcloud-spreed-signaling";
  };

  age.secrets.dei-coturn-secret = {
    file = ../../secrets/dei-coturn-secret.age;
    owner = "turnserver";
    group = "nextcloud-spreed-signaling";
    mode = "0440";
  };

  age.secrets.dei-spreed-session-secret = {
    file = ../../secrets/dei-spreed-session-secret.age;
    owner = "nextcloud-spreed-signaling";
  };

  age.secrets.dei-eurooffice-jwt = {
    file = ../../secrets/dei-onlyoffice-jwt.age;
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    serverName = "${config.services.nextcloud.hostName}";
    enableACME = true;
    forceSSL = true;
  };

  services.nginx.virtualHosts."eurooffice.${config.networking.fqdn}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8081";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."${config.services.coturn.realm}" = {
    serverName = "${config.services.coturn.realm}";
    enableACME = true;
    forceSSL = true;
  };

  services.nginx.virtualHosts."signaling.${config.networking.fqdn}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:8080";
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
        #onlyoffice
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

      eurooffice = pkgs.fetchNextcloudApp {
        appName = "eurooffice";
        appVersion = "11.0.0";
        url = "https://github.com/nextcloud-releases/eurooffice/releases/download/v11.0.0/eurooffice-v11.0.0.tar.gz";
        sha256 = "06pxys91nsvcp57a8i9xyyg5z1zl96anr394bmhchlapsnpgkjsn";
        license = "agpl3Plus";
      };

      files_mindmap = pkgs.fetchNextcloudApp {
        appName = "files_mindmap";
        appVersion = "0.1.0-beta.4";
        url = "https://github.com/nextcloud-releases/files_mindmap/releases/download/v0.1.0-beta.4/files_mindmap-v0.1.0-beta.4.tar.gz";
        sha256 = "sha256-vIvAyLAZZfJXZlXvOihrUXgn2DfJrSEImO+w3Xkoc6Q=";
        license = "agpl3Plus";
      };
    };

    settings = {
      overwriteprotocol = "https";
      overwritehost = "drive.dei.tecnico.ulisboa.pt";
      "overwrite.cli.url" = "https://drive.dei.tecnico.ulisboa.pt/";

      default_phone_region = "PT";

      allow_local_remote_servers = true;

      loglevel = 2;
      log_type = "file";

      user_oidc = {
        auto_provision = true;
        soft_auto_provision = true;
        disable_account_creation = true;

        login_label = "Login via Fenix";
        allow_multiple_user_backends = false;
      };

      eurooffice = {
        DocumentServerUrl = "https://eurooffice.${config.networking.fqdn}/";
        DocumentServerInternalUrl = "http://127.0.0.1:8081/";
        StorageUrl = "https://${config.services.nextcloud.hostName}/";
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

  # NATS is used for the Spreed WebRTC signaling server
  services.nats = {
    enable = true;
    port = 4222;
  };

  # Coturn configuration for WebRTC support in Spreed
  services.coturn = {
    enable = true;
    no-cli = true;
    use-auth-secret = true;
    static-auth-secret-file = config.age.secrets.dei-coturn-secret.path;
    realm = "turn.${config.networking.fqdn}";

    cert = "${config.security.acme.certs."turn.${config.networking.fqdn}".directory}/fullchain.pem";
    pkey = "${config.security.acme.certs."turn.${config.networking.fqdn}".directory}/key.pem";

    extraConfig = ''
      listening-port=3478
      tls-listening-port=5349
    '';
  };

  # Spreed WebRTC signaling server for Nextcloud Talk
  services.nextcloud-spreed-signaling = {
    enable = true;
    package = ncPkgs.nextcloud-spreed-signaling;
    backends = {
      nextcloud = {
        urls = [ "https://${config.services.nextcloud.hostName}" ];
        secretFile = config.age.secrets.dei-spreed-backend-secret.path;
      };
    };
    settings = {
      http = {
        listen = "127.0.0.1:8080";
      };
      nats = {
        url = [ "nats://127.0.0.1:4222" ];
      };
      turn = {
        apikeyFile = config.age.secrets.dei-coturn-secret.path;
        secretFile = config.age.secrets.dei-spreed-backend-secret.path;
        servers = [
          "turn:turn.${config.networking.fqdn}:3478?transport=udp"
          "turn:turn.${config.networking.fqdn}:3478?transport=tcp"
        ];
      };
      clients = {
        internalsecretFile = config.age.secrets.dei-spreed-backend-secret.path;
      };
      sessions = {
        hashkeyFile = config.age.secrets.dei-spreed-session-secret.path;
        blockkeyFile = config.age.secrets.dei-spreed-session-secret.path;
      };
    };
  };

  # Allow necessary ports for Coturn and Spreed WebRTC signaling server
  networking.firewall.allowedTCPPorts = [
    3478
    5349
  ];
  networking.firewall.allowedUDPPorts = [
    3478
    5349
  ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 49152;
      to = 65535;
    }
  ];

  virtualisation.oci-containers.containers.eurooffice = {
    image = "ghcr.io/euro-office/documentserver:latest";
    ports = [ "127.0.0.1:8081:80" ];

    environmentFiles = [
      config.age.secrets.dei-eurooffice-jwt.path
    ];

    environment = {
      USE_UNAUTHORIZED_STORAGE = "true";
    };

    extraOptions = [
      "--add-host=${config.services.nextcloud.hostName}:host-gateway"
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
  documentation.nixos.enable = false;

  systemd.services.phpfpm-nextcloud.path = with pkgs; [
    jre
    pdftk
    openssl
    poppler_utils
  ];
}
