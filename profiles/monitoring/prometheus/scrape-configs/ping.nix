{
  lib,
  nixosConfigurations,
  relabelInstance,
  relabelAddressTargetParam,
  relabelInstanceRegex,
  relabelBlackboxAddress,
  ...
}: let
  hostsIPv4 =
    lib.rnl.filterHosts [(cfg: cfg.rnl.monitoring.ping)] nixosConfigurations;
  hostsIPv6 =
    lib.rnl.filterHosts [(cfg: cfg.rnl.monitoring.ping6)] nixosConfigurations;

  targets = [(cfg: cfg.networking.fqdn)];
in [
  {
    job_name = "ping4";
    metrics_path = "/probe";
    static_configs = lib.rnl.mkStaticConfigs hostsIPv4 targets [];
    params = {
      module = ["ping4"];
    };
    relabel_configs =
      relabelAddressTargetParam
      ++ relabelInstance
      ++ relabelInstanceRegex
      ++ relabelBlackboxAddress;
  }
  {
    job_name = "ping6";
    metrics_path = "/probe";
    static_configs = lib.rnl.mkStaticConfigs hostsIPv6 targets [];
    params = {
      module = ["ping6"];
    };
    relabel_configs =
      relabelAddressTargetParam
      ++ relabelInstance
      ++ relabelInstanceRegex
      ++ relabelBlackboxAddress;
  }
]
