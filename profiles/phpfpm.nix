{ config, ... }:
{
  users.users.php = {
    group = config.services.nginx.group;
    isSystemUser = true;
  };

  services.phpfpm.pools.default = {
    user = "php";
    group = config.services.nginx.group;

    settings = {
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "pm.max_requests" = 500;

      "listen.owner" = config.services.nginx.user;
      "listen.group" = config.services.nginx.group;
    };
  };

  services.nginx.upstreams.php = {
    servers."unix:${config.services.phpfpm.pools.default.socket}" = { };
  };
}
