{ config, ... }:
let
  commonRegistrationFlags = "--output-limit 16384 --docker-oom-kill-disable true --docker-shm-size 0";
  ubuntuImage = "ubuntu:25.10";
  alpineImage = "alpine:latest";
in
{
  imports = [ ./common.nix ];

  services.gitlab-runner.services = {
    CO-A = {
      dockerImage = alpineImage;
      authenticationTokenConfigFile = config.age.secrets."co-a.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 4"
        "--docker-memory 4g"
      ];
      dockerVolumes = [ "/cache" ];
      description = "CO-A runner";
      limit = 1;
    };
    CO-T = {
      dockerImage = alpineImage;
      authenticationTokenConfigFile = config.age.secrets."co-t.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 4"
        "--docker-memory 4g"
      ];
      dockerVolumes = [ "/cache" ];
      description = "CO-T runner";
      limit = 1;
    };
    DEI = {
      dockerImage = alpineImage;
      authenticationTokenConfigFile = config.age.secrets."dei-runner.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 2"
        "--docker-memory 4g"
      ];
      dockerVolumes = [
        "/cache"
      ];
      description = "DEI misc runner";
      limit = 2;
    };
    DMS = {
      dockerImage = alpineImage;
      authenticationTokenConfigFile = config.age.secrets."dms-runner.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 10"
        "--docker-memory 10g"
      ];
      dockerVolumes = [
        "/cache"
      ];
      description = "DEI DMS runner";
      limit = 2;
    };
    ES-operario = {
      dockerImage = ubuntuImage;
      authenticationTokenConfigFile = config.age.secrets."es-runner.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 16"
        "--docker-memory 32g"
      ];
      dockerVolumes = [
        "/cache"
      ];
      description = "ES26 runner";
      limit = 6;
    };
    RNL = {
      dockerImage = ubuntuImage;
      authenticationTokenConfigFile = config.age.secrets."rnl-runner.env".path;
      registrationFlags = [
        commonRegistrationFlags
        "--docker-cpus 2"
        "--docker-memory 10g"
      ];
      dockerVolumes = [ "/cache" ];
      description = "RNL nix";
      limit = 1;
    };
  };

  age.secrets = {
    "co-a.env".file = ../../secrets/gitlab-runners/co-a-runner.age;
    "co-t.env".file = ../../secrets/gitlab-runners/co-t-runner.age;
    "dei-runner.env".file = ../../secrets/gitlab-runners/dei-runner.age;
    "dms-runner.env".file = ../../secrets/gitlab-runners/dms-runner.age;
    "es-runner.env".file = ../../secrets/gitlab-runners/es-runner.age;
    "rnl-runner.env".file = ../../secrets/gitlab-runners/rnl-runner.age;
  };

}
