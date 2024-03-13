{
  lib,
  pkgs,
  config,
  nixosConfigurations,
  relabelEndpoint,
  relabelInstanceRegex,
  relabelAddressTargetParam,
  relabelBlackboxAddress,
  ...
}: let
  hosts =
    lib.rnl.filterHosts [
    ]
    nixosConfigurations;

  targets = [
  ];

  extraLabels = [
    (config: {
      name = "instance";
      value = "${config.networking.fqdn}";
    })
  ];
in {
  metrics_path = "/probe";
  static_configs = lib.rnl.mkStaticConfigs hosts targets extraLabels;
  params = {
    module = ["tcp_connect"];
  };
  relabel_configs =
    relabelAddressTargetParam
    ++ relabelEndpoint
    ++ relabelInstanceRegex
    ++ relabelBlackboxAddress;
}
