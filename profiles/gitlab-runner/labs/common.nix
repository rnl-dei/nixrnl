{ config, lib, ... }:
let
  hasPodman = config.virtualisation.podman.enable;
in
{
  imports = [ ../common.nix ];

  # Support for podman
  virtualisation.podman.dockerSocket.enable = true;
  systemd.services = lib.mkIf hasPodman {
    gitlab-runner = {
      after = [ "podman.service" ];
      requires = [ "podman.service" ];
      serviceConfig.SupplementaryGroups = [ "podman" ];
    };
  };
}
