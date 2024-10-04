{
  pkgs,
  profiles,
  config,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.physical

    webserver
    monitoring.grafana
    monitoring.prometheus
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_241332800309"
        "/dev/disk/by-id/ata-WDC_WDS500G1R0A-68A4W0_241332800370"
      ];
      data = [
        "/dev/disk/by-id/ata-TOSHIBA_HDWQ140_Y8C1K0M7FAYG"
        "/dev/disk/by-id/ata-TOSHIBA_HDWQ140_Y8C6K0J3FAYG"
      ];
    };
  };

  # Networking
  networking = {
    hostId = "0725d120"; # Randomly generated

    interfaces.eno1 = {
      ipv4 = {
        addresses = [
          {
            address = "193.136.164.82";
            prefixLength = 26;
          }
        ];
        routes = [
          {
            address = "0.0.0.0";
            prefixLength = 0;
            via = "193.136.164.126";
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2001:690:2100:81::82";
            prefixLength = 64;
          }
        ];
        routes = [
          {
            address = "::";
            prefixLength = 0;
            via = "2001:690:2100:81::ffff:1";
          }
        ];
      };
    };

    interfaces.mgmt = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.102.1";
            prefixLength = 22;
          }
        ];
        routes = [
          {
            address = "192.168.100.0";
            prefixLength = 22;
            via = "192.168.102.1";
          }
        ];
      };
    };
  };

  users.users.root.hashedPassword = "$6$mDSlBduIvZfDEewk$Y8.JsjcsXhUGd.93qk7j8Wn.Xha/TeWlYlhkC8crYLPTgsoSGIJQXGCXHdZ2p.dFp5srUz9H/R1NinACDpwEv.";

  rnl.internalHost = true;

  # Bind mount /mnt/data/grafana to /var/lib/grafana
  fileSystems."${config.services.grafana.dataDir}" = {
    device = "/mnt/data/grafana";
    options = [ "bind" ];
  };

  # Add Grafana secrets (GitLab Client ID and Secret, Admin Password)
  systemd.services.grafana.serviceConfig.EnvironmentFile =
    config.age.secrets."tardis-grafana.env".path;
  age.secrets."tardis-grafana.env" = {
    file = ../secrets/tardis-grafana-env.age;
    owner = "grafana";
  };

  services.nginx.virtualHosts.grafana.serverName = "grafana.${config.rnl.domain}";
  services.nginx.virtualHosts.prometheus.serverName = "prometheus.${config.rnl.domain}";

  services.nginx.virtualHosts.tardis = {
    serverName = config.networking.fqdn;
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".root = pkgs.writeTextDir "index.html" ''
        <html>
          <head>
            <title>Tardis</title>
          </head>
          <body>
            <h1>Welcome to Tardis</h1>
            <ul>
              <li><a href="https://${config.services.nginx.virtualHosts.grafana.serverName}">Grafana</a></li>
              <li><a href="https://${config.services.nginx.virtualHosts.prometheus.serverName}">Prometheus</a></li>
            </ul>
          </body>
        </html>
      '';
      "/grafana".return = "301 $scheme://${config.services.nginx.virtualHosts.grafana.serverName}";
    };
  };

  # VLANs
  networking.vlans = {
    mgmt = {
      id = config.rnl.vlans.mgmt;
      interface = "eno1";
    };
  };

  # Healthchecks.io
  systemd.timers.healthchecksio = {
    description = "Ping Healthchecks.io every 5 min";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Unit = "healthchecksio.service";
    };
  };
  systemd.services.healthchecksio = {
    description = "Curl Healthchecks.io endpoint";
    serviceConfig.Type = "oneshot";
    script = "${pkgs.curl}/bin/curl $(cat ${config.age.secrets."tardis-healthchecksio.url".path})";
  };
  age.secrets."tardis-healthchecksio.url".file = ../secrets/tardis-healthchecksio-url.age;
}
