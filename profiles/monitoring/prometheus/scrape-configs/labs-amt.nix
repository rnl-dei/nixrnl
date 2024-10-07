{
  lib,
  nixosConfigurations,
  relabelInstance,
  relabelAddressTargetParam,
  relabelBlackboxAddress,
  ...
}:
let
  hosts = lib.rnl.filterHosts [ (cfg: cfg.rnl.monitoring.amt) ] nixosConfigurations;

  targets = [ (cfg: "${cfg.networking.hostName}-mgmt.${cfg.networking.domain}") ];
in
{
  metrics_path = "/probe";
  static_configs = lib.rnl.mkStaticConfigs hosts targets [ ];
  params = {
    module = [ "ping4" ];
  };
  relabel_configs =
    relabelAddressTargetParam
    ++ relabelInstance
    ++
      # Relabel the instance label to the hostname without the mgmt suffix
      [
        {
          source_labels = [ "instance" ];
          target_label = "instance";
          replacement = "\${1}";
          regex = "([^\.]+)-mgmt\..+";
        }
      ]
    ++ relabelBlackboxAddress;
}
