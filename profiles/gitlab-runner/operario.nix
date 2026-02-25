{ config, ... }:
{
  imports = [ ./common.nix ];

  services.gitlab-runner.services = {
    rnl-nix = {
      dockerImage = "ubuntu:25.10";
      authenticationTokenConfigFile = config.age.secrets."rnl-runner.env".path;
      registrationFlags = [
        "--output-limit 16384 --docker-volumes /cache --docker-oom-kill-disable true --docker-cpus 2 --docker-memory 10g"
      ];
      description = "RNL nix";
      limit = 1;
    };
  };

  age.secrets."rnl-runner.env" = {
    file = ../../secrets/gitlab-runners/rnl-runner.age;
  };
}
