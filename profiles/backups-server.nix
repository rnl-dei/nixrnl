{
  config,
  lib,
  options,
  nixosConfigurations,
  ...
}:
let
  # Get all the hosts that have sanoid enabled
  hosts = lib.filterAttrs (
    _name: nixosConfig: nixosConfig.config.services.sanoid.enable
  ) nixosConfigurations;

  # Get list of datasets for each host
  datasets = lib.flatten (
    lib.mapAttrsToList (
      host:
      { config, ... }:
      lib.mapAttrsToList (
        dataset:
        { recursive, ... }:
        {
          inherit recursive;
          source = "${config.services.syncoid.user}@${config.networking.fqdn}:${dataset}";
          target = "dpool/backups/${host}/${dataset}";
        }
      ) config.services.sanoid.datasets
    ) hosts
  );
in
{
  services.openssh.knownHosts = {

    "atlas.rnl.tecnico.ulisboa.pt".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqwR4SAmX8xFuYuNRT7H8/+ktak30cdL6uE0MKcJ7IM";
    "chapek.rnl.tecnico.ulisboa.pt".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICD+onNrj/XB0SgTgqZAZWjpJX67LrvVHq/V1KoxtR1U";
    "dredd.rnl.tecnico.ulisboa.pt".publicKey =
      "AAAAC3NzaC1lZDI1NTE5AAAAIKq8lZJU6rJgiIIYlg9HEIu5qIWUQnyUj7eUyeGQ4oTT";
    "zion.rnl.tecnico.ulisboa.pt".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2fI+xb0S8dOzY8VD3cGRwqG4CfJfEVwcE7cMyymToz";
  };
  services.syncoid = {
    enable = true;
    localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [ "destroy" ];
    interval = lib.mkDefault "*-*-* 03:30:00";
    commonArgs = [ "--delete-target-snapshots" ];
    commands = lib.listToAttrs (
      lib.map (dataset: {
        name = dataset.source;
        value = dataset;
      }) datasets
    );
  };
}
