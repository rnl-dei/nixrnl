{
  config,
  profiles,
  pkgs,
  ...
}:
let
  deiTeamWebsitePort = 3000;
in
{
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.nixos
    type.vm

    containers.docker
    webserver
    fail2ban
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.12";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::12";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";
  };

  rnl.labels.location = "chapek";

  rnl.storage.disks.data = [ "/dev/vdb" ];

  rnl.virtualisation.guest = {
    description = "VM de produção para o DEI";
    createdBy = "nuno.alves";
    maintainers = [ "dei" ];

    vcpu = 4;
    memory = 4096;

    interfaces = [ { source = "pub"; } ];
    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/dei"; }
      { source.dev = "/dev/zvol/dpool/data/dei"; }
    ];
  };

  # DEI
  services.nginx.virtualHosts.dei = {
    serverName = config.networking.fqdn;
    enableACME = true;
    forceSSL = true;
    locations."/".return = "307 https://dei.tecnico.ulisboa.pt";
  };

  # DMS
  dei.dms = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSDnfYmzk0zCktsKjRAphZavsDwXG/ymq+STFff1Zy/" # GitLab CI
    ];
    sites.default.serverName = "dms.dei.tecnico.ulisboa.pt";
  };

  # ODEIO
  dei.odeio = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIpnBeT+Pe1LZt1lAmQzNLCxHSc/8Md1qrUCzfziuBf odeio-CI" # GitLab CI
    ];
    sites.default.serverName = "observatorio.dei.tecnico.ulisboa.pt";
  };

  rnl.db-cluster = {
    ensureDatabases = [
      "dms"
      "leicalumni"
    ];
    ensureUsers = [
      {
        name = "dms";
        ensurePermissions = {
          "dms.*" = "ALL PRIVILEGES";
        };
      }
      {
        name = "leicalumni";
        ensurePermissions = {
          "leicalumni.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx.virtualHosts.redirect-odeio = {
    serverName = "observatorio.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://${config.dei.odeio.sites.default.serverName}$request_uri$is_args$args";
  };

  services.nginx.virtualHosts.redirect-dms = {
    serverName = "dms.${config.networking.fqdn}";
    serverAliases = [ "dms.${config.rnl.domain}" ];
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://${config.dei.dms.sites.default.serverName}$request_uri$is_args$args";
  };

  # Bind mount /mnt/data/dms to /var/lib/dei/dms/default
  fileSystems."${config.dei.dms.sites.default.stateDir}" = {
    device = "/mnt/data/dms";
    options = [ "bind" ];
  };

  # Local database
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "dms" ];
    ensureUsers = [
      {
        name = "dms";
        ensurePermissions = {
          "dms.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Backups
  systemd.timers."backup-prod-db" = {
    description = "Backup DMS production database timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Unit = "backup-prod-db.service";
    };
  };

  systemd.services."backup-prod-db" = {
    description = "Backup DMS production database";
    script = ''
      set -eu
      ${pkgs.mariadb}/bin/mysqldump -u dms -p$DB_PASSWORD dms > /root/dms_backups/dms_backup_$(date +%F).sql
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      EnvironmentFile = config.age.secrets."dms-prod-db-password".path;
    };
  };

  # PhDMS
  dei.phdms.sites.default.serverName = "deic.dei.tecnico.ulisboa.pt";

  services.nginx.virtualHosts.redirect-phdms = {
    serverName = "phdms.${config.networking.fqdn}";
    serverAliases = [ "deic.${config.networking.fqdn}" ];
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://${config.dei.phdms.sites.default.serverName}$request_uri$is_args$args";
  };

  # Bind mount /mnt/data/phdms to /var/lib/dei/phdms/default
  fileSystems."${config.dei.phdms.sites.default.stateDir}" = {
    device = "/mnt/data/phdms";
    options = [ "bind" ];
  };

  # LEIC-Alumni
  dei.leic-alumni.sites.default.serverName = "leicalumni.dei.tecnico.ulisboa.pt";

  # Bind mount /mnt/data/leic-alumni to /var/lib/dei/leic-alumni/default
  fileSystems."${config.dei.leic-alumni.sites.default.stateDir}" = {
    device = "/mnt/data/leic-alumni";
    options = [ "bind" ];
  };

  # Git hooks
  rnl.githook = {
    enable = true;
    hooks = {
      phdms = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:/dei/PhDMS.git";
        path = config.dei.phdms.sites.default.stateDir;
        directoryMode = "0755";
      };
      leic-alumni = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:/dei/arquivo/leic-alumni.git";
        path = config.dei.leic-alumni.sites.default.stateDir;
        directoryMode = "0755";
      };
    };
  };

  systemd.tmpfiles.rules = [ "d /root/.ssh 0755 root root" ];
  age.secrets."root-at-dei-ssh.key" = {
    file = ../secrets/root-at-dei-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
  };

  age.secrets."dms-prod-db-password" = {
    file = ../secrets/dms-prod-db-password.age;
  };

  # Docker config.json with deploy token to access all containers in "DEI" group
  age.secrets."dei-dei-docker-config.json" = {
    file = ../secrets/dei-dei-docker-config.json.age;
    path = "/root/.docker/config.json";
    symlink = true;
  };

  services.nginx.virtualHosts."dei-team" = {
    serverName = "equipa.dei.tecnico.ulisboa.pt";
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".proxyPass = "http://localhost:${toString deiTeamWebsitePort}";
    };
  };

  services.nginx.virtualHosts.redirect-team = {
    serverName = "equipa.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://equipa.dei.tecnico.ulisboa.pt$request_uri$is_args$args";
  };

  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "${config.age.secrets."dei-dei-docker-config.json".path}:/config.json"
    ];
    environment = {
      "WATCHTOWER_LABEL_ENABLE" = "true"; # Filter containers by label "com.centurylinklabs.watchtower.enable"
      "WATCHTOWER_POLL_INTERVAL" = "300"; # 5 minutes
    };
  };

  virtualisation.oci-containers.containers."dei-team-website" = {
    image = "registry.rnl.tecnico.ulisboa.pt/dei/website:latest";
    ports = [ "${toString deiTeamWebsitePort}:80" ];
    labels = {
      "com.centurylinklabs.watchtower.enable" = "true";
    };
  };

  # GlitchTip
  services.glitchtip = {
    enable = true;
    glitchtipImage = "glitchtip/glitchtip:v4.0";
    secretKeyFile = config.age.secrets."dei-glitchtip-secret-key".path;
    databaseEnvFile = config.age.secrets."dei-glitchtip-database-env".path;
    emailUrl = "smtp://${config.rnl.mailserver.host}:${toString config.rnl.mailserver.port}";
  };

  services.nginx.virtualHosts.glitchtip.locations."/".extraConfig = ''
    # RNL IPs
    allow 193.136.164.0/24;
    allow 2001:690:2100:80::/62;

    deny all;
  '';

  # Bind mount /mnt/data/glitctip to /var/lib/glitchtip
  fileSystems."${config.services.glitchtip.stateDir}" = {
    device = "/mnt/data/glitchtip";
    options = [ "bind" ];
  };

  age.secrets."dei-glitchtip-secret-key" = {
    file = ../secrets/dei-glitchtip-secret-key.age;
  };

  age.secrets."dei-glitchtip-database-env" = {
    file = ../secrets/dei-glitchtip-database-env.age;
  };
}
