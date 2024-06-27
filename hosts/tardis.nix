{
  profiles,
  config,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.physical

    monitoring.grafana
    monitoring.prometheus
  ];

  rnl.labels.location = "inf1-p01-a2";

  # Storage
  rnl.storage = {
    disks = {
      root = [
        # TODO: Add root disk (2 SSDs of >200 GB)
      ];
      data = [
        # TODO: Add data disks (2 HDD disks of 3TB each is enough)
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

  # Bind mount /mnt/data/grafana to /var/lib/grafana
  fileSystems."${config.services.grafana.dataDir}" = {
    device = "/mnt/data/grafana";
    options = ["bind"];
  };

  # Add Grafana secrets (GitLab Client ID and Secret, Admin Password)
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.age.secrets."tardis-grafana.env".path;
  age.secrets."tardis-grafana.env" = {
    file = ../secrets/tardis-grafana-env.age;
    owner = "grafana";
  };

  # Add Prometheus SNMP Exporter secrets
  age.secrets."tardis-snmp-exporter.env" = {
    file = ../secrets/tardis-snmp-exporter-env.age;
    owner = "snmp-exporter";
  };

  services.nginx.virtualHosts.grafana.serverName = "grafana.${config.rnl.domain}";
  services.nginx.virtualHosts.prometheus.serverName = "prometheus.${config.rnl.domain}";

  # VLANs
  networking.vlans = {
    mgmt = {
      id = config.rnl.vlans.mgmt;
      interface = "eno1";
    };
  };
}
