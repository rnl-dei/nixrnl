{
  config,
  lib,
  ...
} @ args: let
  # Relabeling rules for Prometheus
  relabeling = {
    relabelInstance = [
      {
        source_labels = ["__address__"];
        target_label = "instance";
      }
    ];
    relabelInstanceRegex = [
      {
        source_labels = ["instance"];
        target_label = "instance";
        replacement = "\${1}";
        regex = "([^\.]+)\..+";
      }
    ];
    relabelEndpoint = [
      {
        source_labels = ["__address__"];
        target_label = "endpoint";
      }
    ];
    relabelAddressTargetParam = [
      {
        source_labels = ["__address__"];
        target_label = "__param_target";
      }
    ];
    relabelBlackboxAddress = [
      {
        target_label = "__address__";
        replacement = "${config.networking.fqdn}:${toString config.services.prometheus.exporters.blackbox.port}";
      }
    ];
  };

  extraArgs = {} // relabeling;

  # TODO: Write documentation
  mkScrapeConfigs = dir:
    lib.lists.flatten (
      lib.mapAttrsToList
      (
        path: _: let
          cfg' = import (dir + "/${path}") (args // extraArgs);
          cfgs = lib.toList cfg';
        in (builtins.map
          (
            cfg: ({job_name = lib.removeSuffix ".nix" path;} // cfg)
          )
          cfgs)
      )
      (builtins.readDir dir)
    );
in {
  # Prometheus
  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${config.services.nginx.virtualHosts.prometheus.serverName}";
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    scrapeConfigs = mkScrapeConfigs ./scrape-configs;
  };
  services.nginx.upstreams.prometheus.servers = {
    "localhost:${toString config.services.prometheus.port}" = {};
  };
  services.nginx.virtualHosts.prometheus = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    enableACME = true;
    addSSL = true;
    locations."/".proxyPass = "http://prometheus";
  };

  # Blackbox exporter
  services.prometheus.exporters.blackbox = {
    enable = true;
    configFile = ./blackbox.yml;
  };
}
