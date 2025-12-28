{
  pkgs,
  config,
  ...
}:
let
  s3-dei-domain = "s3.blatta.${config.rnl.domain}";
  s3-admin-dei-domain = "s3-admin.blatta.${config.rnl.domain}";

in
{
  age.secrets.garage-env-file = {
    file = ../../secrets/dei-garage-env-file.env.age;
    owner = "garage";
    path = "/etc/garage.env";
  };

  services.nginx.virtualHosts."${s3-dei-domain}" = {
    serverName = "${s3-dei-domain}";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:3900";
    };
  };
  services.nginx.virtualHosts."${s3-admin-dei-domain}" = {
    serverName = "${s3-admin-dei-domain}";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:3903";
    };
  };
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    environmentFile = config.age.secrets.garage-env-file.path;
    settings = {
      replication_factor = 1;
      rpc_bind_addr = "[::]:3901";
      s3_api = {
        api_bind_addr = "[::]:3900";
        s3_region = "garage";
        root_domain = "${s3-dei-domain}";
      };
      admin = {
        api_bind_addr = "[::]:3903";
        metrics_require_token = true;
      };
    };
  };
}
