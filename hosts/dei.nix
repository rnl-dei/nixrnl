{
  config,
  profiles,
  pkgs,
  ...
}: {
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
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.12";
          prefixLength = 26;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.62";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:80::12";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:80::ffff:1";
        }
      ];
    };
  };

  rnl.labels.location = "chapek";

  rnl.storage.disks.data = ["/dev/vdb"];

  rnl.virtualisation.guest = {
    description = "VM de produção para o DEI";
    createdBy = "nuno.alves";
    maintainers = ["dei"];

    vcpu = 4;
    memory = 4096;

    interfaces = [{source = "pub";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/dei";}
      {source.dev = "/dev/zvol/dpool/data/dei";}
    ];
  };

  # DEI
  services.nginx.virtualHosts.dei = {
    serverName = config.networking.fqdn;
    serverAliases = ["equipa.dei.tecnico.ulisboa.pt" "equipa.${config.networking.fqdn}"];
    enableACME = true;
    forceSSL = true;
    locations."/".return = "307 https://dei.tecnico.ulisboa.pt"; # TODO: Fix team website
  };

  # DMS
  dei.dms = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSDnfYmzk0zCktsKjRAphZavsDwXG/ymq+STFff1Zy/" # GitLab CI
    ];
    sites.default.serverName = "dms.dei.tecnico.ulisboa.pt";
  };

  services.nginx.virtualHosts.redirect-dms = {
    serverName = "dms.${config.networking.fqdn}";
    serverAliases = ["dms.${config.rnl.domain}"];
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://${config.dei.dms.sites.default.serverName}$request_uri$is_args$args";
  };

  # Bind mount /mnt/data/dms to /var/lib/dei/dms/default
  fileSystems."${config.dei.dms.sites.default.stateDir}" = {
    device = "/mnt/data/dms";
    options = ["bind"];
  };

  # Local database
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["dms"];
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
      ${pkgs.mariadb}/bin/mysqldump -u dms -p$DB_PASSWORD dms > ~/dms_backups/dms_backup_$(date +%F).sql
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
    serverAliases = ["deic.${config.networking.fqdn}"];
    enableACME = true;
    forceSSL = true;
    locations."/".return = "301 https://${config.dei.phdms.sites.default.serverName}$request_uri$is_args$args";
  };

  # Bind mount /mnt/data/phdms to /var/lib/dei/phdms/default
  fileSystems."${config.dei.phdms.sites.default.stateDir}" = {
    device = "/mnt/data/phdms";
    options = ["bind"];
  };

  # LEIC-Alumni
  dei.leic-alumni.sites.default.serverName = "leicalumni.dei.tecnico.ulisboa.pt";

  # Bind mount /mnt/data/leic-alumni to /var/lib/dei/leic-alumni/default
  fileSystems."${config.dei.leic-alumni.sites.default.stateDir}" = {
    device = "/mnt/data/leic-alumni";
    options = ["bind"];
  };

  # GlitchTip
  # Docker-compose inside of the machine
  # TODO: Move this to NixOS Configuration
  services.nginx.virtualHosts.glitchtip = {
    serverName = "glitchtip.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8000";
      extraConfig = ''
        # RNL IPs
        allow 193.136.164.0/24;
        allow 2001:690:2100:80::/62;

        deny all;
      '';
    };
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

  systemd.tmpfiles.rules = ["d /root/.ssh 0755 root root"];
  age.secrets."root-at-dei-ssh.key" = {
    file = ../secrets/root-at-dei-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
  };

  age.secrets."dms-prod-db-password" = {
    file = ../secrets/dms-prod-db-password.age;
  };
}
