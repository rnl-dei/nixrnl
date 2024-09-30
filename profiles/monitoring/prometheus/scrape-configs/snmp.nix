{
  lib,
  nixosConfigurations,
  relabelAddressTargetParam,
  relabelInstance,
  relabelInstanceRegex,
  relabelSNMPAddress,
  ...
}: let
  hostsNetworkZeus =
    lib.rnl.filterHosts [
      (cfg: cfg.rnl.monitoring.snmp)
      (cfg: cfg.rnl.labels.type == "router")
      (cfg: cfg.rnl.labels.os == "junos")
    ]
    nixosConfigurations;

  hostsNetworkSwitch =
    lib.rnl.filterHosts [
      (cfg: cfg.rnl.monitoring.snmp)
      (cfg: cfg.rnl.labels.type == "switch")
    ]
    nixosConfigurations;

  hostsEnergyUPS =
    lib.rnl.filterHosts [
      (cfg: cfg.rnl.monitoring.snmp)
      (cfg: cfg.rnl.labels.type == "ups")
    ]
    nixosConfigurations;

  hostsEnergyPDU =
    lib.rnl.filterHosts [
      (cfg: cfg.rnl.monitoring.snmp)
      (cfg: cfg.rnl.labels.type == "pdu")
    ]
    nixosConfigurations;

  targets = [(cfg: cfg.networking.fqdn)];

  defaultConfig = {
    metrics_path = "/snmp";
    relabel_configs =
      relabelAddressTargetParam
      ++ relabelInstance
      ++ relabelInstanceRegex
      ++ relabelSNMPAddress;
  };
in
  builtins.map (elm: defaultConfig // elm) [
    {
      job_name = "snmp-network-zeus";
      static_configs = lib.rnl.mkStaticConfigs hostsNetworkZeus targets [];
      scrape_interval = "1m";
      scrape_timeout = "30s";
      params = {
        module = ["network-zeus"];
        auth = ["zeus_auth"];
      };
    }
    {
      job_name = "snmp-network-switch";
      static_configs = lib.rnl.mkStaticConfigs hostsNetworkSwitch targets [];
      params = {
        module = ["network-switch"];
      };
    }
    {
      job_name = "snmp-energy-ups";
      static_configs = lib.rnl.mkStaticConfigs hostsEnergyUPS targets [];
      params = {
        module = ["energy-ups"];
      };
    }
    {
      job_name = "snmp-energy-pdu";
      static_configs = lib.rnl.mkStaticConfigs hostsEnergyPDU targets [];
      params = {
        module = ["energy-pdu"];
      };
    }
  ]
