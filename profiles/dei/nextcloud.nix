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

    hostName = "dei-drive.blatta.rnl.tecnico.ulisboa.pt";

    maxUploadSize = "16G";
    https = true;

    autoUpdateApps = {
      enable = true;
      startAt = "05:00:00";
    };

    extraAppsEnable = true;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) groupfolders onlyoffice user_oidc;
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
    hostname = "onlyoffice.blatta.rnl.tecnico.ulisboa.pt";

    jwtSecretFile = config.age.secrets.dei-onlyoffice-jwt.path;
  };
}
