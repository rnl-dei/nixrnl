{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.sanoid = {
    enable = true;
    interval = "hourly"; # How often to run sanoid

    templates = {
      data = {
        monthly = 1; # Keep 6 monthly snapshots
        daily = 7; # Keep 15 daily snapshots
        hourly = 24; # Keep 24 hourly snapshots

        autoprune = true;
        autosnap = true;
      };
    };

    datasets = lib.mkDefault {
      "dpool/data" = {
        use_template = [ "data" ];
        recursive = true;
      };
    };
  };
  users.groups.syncoid = { };
  users.users."${config.services.syncoid.user}" = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6TPOIkgSoqhathevsglhNtvydbpHSudnxF2Eg/PNWs syncoid@caixote"
    ];
    isSystemUser = true;
    group = "syncoid";
    shell = "/bin/sh";
    packages = [
      pkgs.lzop
      pkgs.mbuffer
    ];
  };
  systemd.services.syncoid-permissions =
    let
      datasets = lib.mapAttrsToList (
        name:
        {
          recursive ? false,
          ...
        }:
        (lib.optionalString (!recursive) "-l ") + name
      ) config.services.sanoid.datasets;
      permissions = [
        "send"
        "snapshot"
        "hold"
      ]; # TODO: Might need to add permissions
      user = config.services.syncoid.user;

      buildAllowCommand =
        zfsAction: dataset:
        lib.escapeShellArgs [
          # Here we explicitly use the booted system to guarantee the stable API needed by ZFS
          "-+/run/booted-system/sw/bin/zfs"
          zfsAction
          user
          (builtins.concatStringsSep "," permissions)
          dataset
        ];
    in
    {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        RemainAfterExit = true;
        ExecStart = builtins.map (dataset: buildAllowCommand "allow" dataset) datasets;
        ExecStop = builtins.map (dataset: buildAllowCommand "unallow" dataset) datasets;
      };
    };
}
