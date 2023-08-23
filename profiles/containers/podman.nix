{...}: {
  imports = [./common.nix];

  virtualisation = {
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  # Allow podman if not root
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';
}
