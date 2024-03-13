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
      (c: c.services.nginx.enable)
    ]
    nixosConfigurations;

  targets = [
    (
      config:
        lib.mapAttrsToList (_: v: v.serverName)
        (lib.filterAttrs (_: v: v.serverName != null) config.services.nginx.virtualHosts)
    ) # TODO: Map through locations
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
    module = ["http_2xx"];
  };
  relabel_configs =
    relabelAddressTargetParam
    ++ relabelEndpoint
    ++ relabelInstanceRegex
    ++ relabelBlackboxAddress;
}
