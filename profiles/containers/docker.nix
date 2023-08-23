{...}: {
  imports = [./common.nix];

  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;
    };
  };
}
