{ config, ... }:
{
  imports = [ ./common.nix ];

  services.gitlab-runner.services = {
    rnl-nix = {
      dockerImage = "ubuntu:25.10";
      authenticationTokenConfigFile = config.age.secrets."rnl-runner.env".path;
      registrationFlags = [ "--output-limit=16384" ];
      description = "RNL nix";
      limit = 2;
    };
  };

  age.secrets."rnl-runner.env" = {
    file = ../../secrets/gitlab-runners/rnl-runner.age;
  };
}
