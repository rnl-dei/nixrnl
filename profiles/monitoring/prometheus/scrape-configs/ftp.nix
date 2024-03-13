{
  lib,
  nixosConfigurations,
  relabelInstance,
  relabelInstanceRegex,
  relabelAddressTargetParam,
  relabelBlackboxAddress,
  ...
}: let
  hosts =
    lib.rnl.filterHosts [
      (cfg: cfg.networking.hostName == "ftp") # FIXME: Choose a better condition
    ]
    nixosConfigurations;

  targets = [
    (cfg: "${cfg.networking.fqdn}:21") # FIXME: Choose a better port
  ];
in {
  job_name = "ftp";
  metrics_path = "/probe";
  static_configs = lib.rnl.mkStaticConfigs hosts targets [];
  params = {
    module = ["ftp_connect"];
  };
  relabel_configs =
    relabelAddressTargetParam
    ++ relabelInstance
    ++ relabelInstanceRegex
    ++ relabelBlackboxAddress;
}
