# Auto-generated using compose2nix v0.3.1.
{
  pkgs,
  lib,
  config,
  ...
}:

{

  age.secrets.kutt-env = {
    file = ../secrets/kutt-env.age;
  };

  age.secrets.kutt-postgres-env = {
    file = ../secrets/kutt-postgres-env.age;
  };

  age.secrets.kutt-registry = {
    file = ../secrets/kutt-registry.age;
  };

  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."kutt-kutt" = {
    image = "registry.rnl.tecnico.ulisboa.pt/rnl/infra/kutt:latest";
    login = {
      username = "richardstallman";
      registry = "https://registry.rnl.tecnico.ulisboa.pt";
      passwordFile = config.age.secrets.kutt-registry.path;
    };
    environmentFiles = [ config.age.secrets.kutt-env.path ];
    ports = [
      "3000:3000/tcp"
    ];
    cmd = [
      "./wait-for-it.sh"
      "postgres:5432"
      "--"
      "npm"
      "start"
    ];
    dependsOn = [
      "kutt-postgres"
      "kutt-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=kutt"
      "--network=kutt_default"
    ];
  };
  systemd.services."docker-kutt-kutt" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-kutt_default.service"
    ];
    requires = [
      "docker-network-kutt_default.service"
    ];
    partOf = [
      "docker-compose-kutt-root.target"
    ];
    wantedBy = [
      "docker-compose-kutt-root.target"
    ];
  };
  virtualisation.oci-containers.containers."kutt-postgres" = {
    image = "postgres:12-alpine";
    environmentFiles = [ config.age.secrets.kutt-postgres-env.path ];
    volumes = [
      "/var/lib/kutt/kutt_postgres_data:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=postgres"
      "--network=kutt_default"
    ];
  };
  systemd.services."docker-kutt-postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-kutt_default.service"
      "docker-volume-kutt_postgres_data.service"
    ];
    requires = [
      "docker-network-kutt_default.service"
      "docker-volume-kutt_postgres_data.service"
    ];
    partOf = [
      "docker-compose-kutt-root.target"
    ];
    wantedBy = [
      "docker-compose-kutt-root.target"
    ];
  };
  virtualisation.oci-containers.containers."kutt-redis" = {
    image = "redis:6.0-alpine";
    volumes = [
      "/var/lib/kutt/kutt_redis_data:/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=redis"
      "--network=kutt_default"
    ];
  };
  systemd.services."docker-kutt-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
      RestartMaxDelaySec = lib.mkOverride 90 "1m";
      RestartSec = lib.mkOverride 90 "100ms";
      RestartSteps = lib.mkOverride 90 9;
    };
    after = [
      "docker-network-kutt_default.service"
      "docker-volume-kutt_redis_data.service"
    ];
    requires = [
      "docker-network-kutt_default.service"
      "docker-volume-kutt_redis_data.service"
    ];
    partOf = [
      "docker-compose-kutt-root.target"
    ];
    wantedBy = [
      "docker-compose-kutt-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-kutt_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f kutt_default";
    };
    script = ''
      docker network inspect kutt_default || docker network create kutt_default
    '';
    partOf = [ "docker-compose-kutt-root.target" ];
    wantedBy = [ "docker-compose-kutt-root.target" ];
  };

  # Volumes
  systemd.services."docker-volume-kutt_postgres_data" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect kutt_postgres_data || docker volume create kutt_postgres_data
    '';
    partOf = [ "docker-compose-kutt-root.target" ];
    wantedBy = [ "docker-compose-kutt-root.target" ];
  };
  systemd.services."docker-volume-kutt_redis_data" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect kutt_redis_data || docker volume create kutt_redis_data
    '';
    partOf = [ "docker-compose-kutt-root.target" ];
    wantedBy = [ "docker-compose-kutt-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-kutt-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
