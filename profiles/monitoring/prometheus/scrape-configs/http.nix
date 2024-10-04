{
  lib,
  nixosConfigurations,
  relabelEndpoint,
  relabelInstanceRegex,
  relabelAddressTargetParam,
  relabelBlackboxAddress,
  ...
}:
let
  hosts = lib.rnl.filterHosts [ (c: c.services.nginx.enable) ] nixosConfigurations;

  hasSSL = v: v.onlySSL || v.enableSSL || v.addSSL || v.forceSSL;

  targets = [
    (
      config:
      lib.mapAttrsToList (_: v: "http${lib.optionalString (hasSSL v) "s"}://${v.serverName}") (
        lib.filterAttrs (_: v: v.serverName != null) config.services.nginx.virtualHosts
      )
    )
  ];

  extraLabels = [
    (config: {
      name = "instance";
      value = "${config.networking.fqdn}";
    })
  ];
in
{
  metrics_path = "/probe";
  static_configs = lib.rnl.mkStaticConfigs hosts targets extraLabels;
  params = {
    module = [ "http_2xx" ];
  };
  relabel_configs =
    relabelAddressTargetParam ++ relabelEndpoint ++ relabelInstanceRegex ++ relabelBlackboxAddress;
}
