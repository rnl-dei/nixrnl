{
  lib,
  nixosConfigurations,
  relabelInstance,
  relabelInstanceRegex,
  ...
}: let
  hosts =
    lib.rnl.filterHosts [
      (cfg: cfg.services.prometheus.exporters.node.enable)
    ]
    nixosConfigurations;

  targets = [
    (config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}")
  ];
in {
  static_configs = lib.rnl.mkStaticConfigs hosts targets [];
  relabel_configs = relabelInstance ++ relabelInstanceRegex;
}
