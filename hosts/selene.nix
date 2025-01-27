{
  config,
  lib,
  profiles,
  pkgs,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    webserver
    ist-delegate-election
    fail2ban
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.146";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:83::146";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";
  };

  # Nginx Catch-All
  services.nginx.virtualHosts.ist-delegate-election.serverName = "delegados.${config.rnl.domain}";
  services.nginx.virtualHosts.catch-all = {
    serverName = config.networking.fqdn;
    default = true;
    enableACME = true;
    addSSL = true;
    locations."/".return = "301 https://helios.${config.rnl.domain}$request_uri";
  };

  # Helios Voting System
  rnl.githook = {
    enable = true;
    hooks.helios-server = {
      url = "git@gitlab.rnl.tecnico.ulisboa.pt:/dei/helios-server.git";
      path = "/var/lib/helios-server";
      directoryMode = "0755";
    };
  };
  services.uwsgi = {
    enable = true;
    group = config.services.nginx.group;
    plugins = [ "python3" ];
    instance =
      let
        heliosServerDir = config.rnl.githook.hooks.helios-server.path;
      in
      {
        type = "emperor";
        vassals.helios = {
          type = "normal";
          chdir = heliosServerDir;
          wsgi-file = "${heliosServerDir}/wsgi.py";
          socket = "${config.services.uwsgi.runDir}/helios.sock";
          chmod-socket = "660";
          virtualenv = "${heliosServerDir}/venv";
          attach-daemon2 = "cmd=./run-celery.sh,daemonize";
          env = lib.mapAttrsToList (n: v: "${n}=${v}") {
            PATH = lib.makeBinPath [ pkgs.bash ]; # for run-celery.sh

            ENVIRONMENT_FILE = config.age.secrets."helios.env".path;

            URL_HOST = "https://helios.${config.rnl.domain}";
            ALLOWED_HOSTS = "helios.${config.rnl.domain}";
            SSL = "1";

            DEFAULT_FROM_EMAIL = "noreply@helios.${config.rnl.domain}";
            DEFAULT_FROM_NAME = "Voting at DEI";
            EMAIL_HOST = config.rnl.mailserver.host;
            EMAIL_PORT = toString config.rnl.mailserver.port;
            EMAIL_USE_TLS = "0";

            SITE_TITLE = "Voting@DEI";

            WELCOME_MESSAGE = "Welcome to DEI's voting system.";
            HELP_EMAIL_ADDRESS = "dei@${config.rnl.domain}";

            ADMIN_NAME = "Administrator";
            ADMIN_EMAIL = "dei-robots@${config.rnl.domain}";

            AUTH_ENABLED_SYSTEMS = "fenix";
            AUTH_DEFAULT_SYSTEM = "fenix";

            FENIX_ADDRESS = "https://fenix.tecnico.ulisboa.pt";
            FENIX_REDIRECT_URL = "https://helios.${config.rnl.domain}/auth/after";
            FENIX_ALLOWED_USERS_TO_CREATE_ELECTIONS = lib.concatStringsSep "," [
              "ist23745" # Lurdes
              "ist23000" # JLuis
              "ist1103252" # JPereira
            ];

            DEBUG = "0";
          };
        };
      };
  };
  services.nginx.virtualHosts."helios" = {
    serverName = "helios.${config.rnl.domain}";
    enableACME = true;
    forceSSL = true;
    locations."/".extraConfig = ''
      uwsgi_pass unix:${config.services.uwsgi.instance.vassals.helios.socket};
      include ${config.services.nginx.package}/conf/uwsgi_params;
    '';
  };
  services.rabbitmq.enable = true;
  services.postgresql = {
    enable = true;
    authentication = ''
      local helios helios trust
    '';
    ensureDatabases = [ "helios" ];
    ensureUsers = [
      {
        name = "root";
        ensureClauses.superuser = true;
      }
      {
        name = "helios";
        ensureDBOwnership = true;
      }
    ];
  };

  age.secrets."helios.env" = {
    file = ../secrets/helios-env.age;
    owner = config.services.uwsgi.user;
  };

  age.secrets."root-at-selene" = {
    file = ../secrets/root-at-selene-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
  };

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "IST Delegate Election system";
    createdBy = "nuno.alves";

    interfaces = [ { source = "dmz"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/selene"; } ];
  };
}
