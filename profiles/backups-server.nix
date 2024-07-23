{
  lib,
  nixosConfigurations,
  ...
}: let
  # Get all the hosts that have sanoid enabled
  hosts =
    lib.filterAttrs (
      name: value:
        value.config.services.sanoid.enable
    )
    nixosConfigurations;

  # Get list of datasets for each host
  datasets = lib.flatten (lib.mapAttrsToList (
      host: {config, ...}:
        lib.mapAttrsToList (dataset: {recursive, ...}: {
          inherit recursive;
          source = "${config.services.syncoid.user}@${config.networking.fqdn}:${dataset}";
          target = "dpool/backups/${host}/${dataset}";
        })
        config.services.sanoid.datasets
    )
    hosts);
in {
  services.syncoid = {
    enable = true;
    interval = lib.mkDefault "*-*-* 3:30:00";
    commands = lib.listToAttrs (lib.map (dataset: {
        name = dataset.source;
        value = dataset;
      })
      datasets);
  };
}
