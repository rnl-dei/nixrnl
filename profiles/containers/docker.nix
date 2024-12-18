{ ... }:
{
  imports = [ ./common.nix ];

  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;
      autoPrune.enable = true; # Don't run out of space
    };
  };
}
