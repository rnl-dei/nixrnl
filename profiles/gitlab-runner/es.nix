{ config, ... }:
{
  imports = [ ./common.nix ];

  services.gitlab-runner = {
    services = {
      es = {
        dockerImage = "ubuntu:23.10";
        authenticationTokenConfigFile = config.age.secrets."gl-runner-es.env".path;
        registrationFlags = [ "--output-limit=16384 --docker-host unix:///var/run/podman/podman.sock" ];
        description = "gitlab-runner-es";
      };
    };
  };

  age.secrets."gl-runner-es.env" = {
    file = ../../secrets/gitlab-runners/es-25-env.age;
  };
}
