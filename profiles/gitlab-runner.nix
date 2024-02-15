{
  config,
  lib,
  ...
}: {
  services.gitlab-runner = {
    enable = true;
    services = {
      default = {
        dockerImage = "ubuntu:23.10";
        registrationFlags = [
          "--locked=false"
          "--output-limit=16384"
        ];
      };
    };
  };
}
