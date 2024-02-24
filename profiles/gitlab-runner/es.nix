{config, ...}: {
  imports = [./common.nix];

  services.gitlab-runner = {
    services = {
      es = {
        dockerImage = "ubuntu:23.10";
        registrationConfigFile = config.age.secrets."gl-runner-es.env".path;
        registrationFlags = ["--output-limit=16384"];
        description = "gitlab-runner-es";
      };
    };
  };

  age.secrets."gl-runner-es.env" = {
    file = ../../secrets/gitlab-runners/es-24-env.age;
  };
}
