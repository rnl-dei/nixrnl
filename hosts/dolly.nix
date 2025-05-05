{
  config,
  lib,
  pkgs,
  profiles,
  nixosConfigurations,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.physical

    pixiecore
    opentracker
    transmission.labs
  ];

  rnl.labels.location = "inf1-p01-a3";

  # Storage
  rnl.storage.disks.root = [ "/dev/disk/by-id/ata-WDC_WD1002F9YZ-09H1JL1_WD-WMC5K0D3AW7K" ];

  # Networking
  networking = {
    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "193.136.154.125";
          prefixLength = 25;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:84:8000::125";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.154.126";
    defaultGateway6.address = "2001:690:2100:84:ffff:ffff:ffff:1";
  };

  users.users.root.hashedPassword = "$6$MCkbho3x/A5sP6hN$m0w6oxl8h8fj1QcVm6Eu9OIQUdjZRNcs.qP/qw.s7K1nrWdsOwp1fQUsJIV0k3DO5PxrOu/UIR/b5XZSyXwML0";

  environment.shellAliases = {
    create-torrent = "transmission-create -p -t udp://tracker.${config.rnl.domain}:31000";
  };

  # WoL Bridge
  rnl.wolbridge = {
    enable = true;
    openFirewall = true;
    domain = config.rnl.domain;
    pingHosts = [ "193.136.154.{0..125}" ];
    configFile =
      let
        labs =
          builtins.foldl'
            (
              acc: hostname:
              let
                lab = builtins.elemAt (builtins.split "p" hostname) 0;
              in
              acc // { ${lab} = acc."${lab}" or [ ] ++ [ hostname ]; }
            )
            { }
            (
              builtins.filter (hostname: builtins.match "lab([0-9]+|X)p[0-9]+" hostname != null) (
                builtins.attrNames nixosConfigurations
              )
            );

        config = labs // {
          all = builtins.attrNames labs;
        };
      in
      pkgs.writeText "wolbridge-config.json" (lib.generators.toJSON { } config);
  };
}
