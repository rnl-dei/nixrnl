{...}: {
  imports = [../common.nix];

  virtualisation = {
    oci-containers.backend = "podman";

    podman = {
      enable = true;
    };

    docker.enable = false;
  };
}
