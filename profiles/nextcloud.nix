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
        sha256 = "sha256:0p22chwcyksj099af40210i299jvmp33757qmm1nfma872k8pwmw";
      })
      {
        system = pkgs.system;
        config.allowUnfree = true;
      };
in
{
  age.secrets.nextcloud-secrets = {
    file = ../secrets/rnl-nextcloud-secrets.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/nextcloud-secrets";
  };

  age.secrets.nextcloud-admin-pass = {
    file = ../secrets/rnl-nextcloud-admin-pass.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/nextcloud-admin-pass";
  };

  age.secrets.nextcloud-oidc = {
    file = ../secrets/rnl-nextcloud-oidc.age;
    owner = "nextcloud";
    path = "/var/lib/nextcloud/nextcloud-oidc";
  };

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    serverName = "${config.services.nextcloud.hostName}";
    enableACME = true;
    forceSSL = true;
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

    hostName = "drive.rnl.tecnico.ulisboa.pt";

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
        calendar
        contacts
        files_automatedtagging
        forms
        #user_saml // todo: contact dsi for saml support
        ;

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

    settings = {
      overwriteProtocol = "https";

      default_phone_region = "PT";

      allow_local_remote_servers = true;

      loglevel = 2;
      log_type = "file";

    };

    database.createLocally = true;
    configureRedis = true;

    config = {
      dbtype = "pgsql";

      adminpassFile = config.age.secrets.nextcloud-admin-pass.path;
      adminuser = "admin";

      objectstore.s3 = {
        enable = true;

        useSsl = false;
        usePathStyle = true;
        verify_bucket_exists = false;

        hostname = "193.136.164.35:7480";
        bucket = "rnl-nextcloud";
        secretFile = config.age.secrets.nextcloud-secrets.path;
        key = "O7AMB0WCIHPEZDAXZZOI"; # access key id, normally public
      };
    };
  };

  # There are some settings that are not possible to set via the Nextcloud config,
  # so we create a systemd service that runs once after Nextcloud setup to apply them
  # all this to have an "declarative" configuration via Nix
  systemd.services.nextcloud-runtime-config = {
    description = "Nextcloud runtime settings (OIDC)";
    after = [ "nextcloud-setup.service" ];
    requires = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [ openssl ]; # Ensure OpenSSL is available to the OCC script environment

    serviceConfig = {
      Type = "oneshot";
    };

    script =
      let
        nextcloudOcc = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
      in
      ''
        ${nextcloudOcc} -- group_default_quota:set \
          DEFAULT 0B

        ${nextcloudOcc} -- group_default_quota:set \
          Faculty 5GB

        ${nextcloudOcc} -- group_default_quota:set \
          Student 1GB
      '';
  };

  fileSystems."/var/lib/elasticsearch" = {
    device = "/mnt/data/elasticsearch";
    options = [ "bind" ];
  };

  services.elasticsearch = {
    enable = true; # with 32 cpu cores it will work... surely
    package = pkgs.elasticsearch7;

    plugins = [ pkgs.elasticsearchPlugins.ingest-attachment ];

    listenAddress = "127.0.0.1";
    port = 9200;

    extraJavaOptions = [
      "-Xms2g"
      "-Xmx2g"
    ];
  };

  # 1. Allow LibreSign's downloaded pre-compiled binaries to execute on NixOS
  programs.nix-ld.enable = true;

  # 2. Forcefully inject the PATH into the PHP-FPM web workers
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
    # for elasticsearch:
    perl
    which
    poppler_utils # pdftotext
    tesseract # OCR
    catdoc # .doc
    gawk
    gnugrep
    antiword
    unrtf
  ];
}
