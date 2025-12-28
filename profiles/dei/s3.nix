{
  pkgs,
  config,
  ...
}:
{
  age.secrets.garage-env-file = {
    file = ../../secrets/dei-garage-env-file.age;
    owner = "garage";
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
        root_domain = ".s3.garage";
      };
    };
  };
}
