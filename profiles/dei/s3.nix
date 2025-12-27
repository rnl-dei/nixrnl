{
  pkgs,
  ...
}:
{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {
      rpc_bind_addr = "[::]:3901";
      s3_api = {
        api_bind_addr = "[::]:3900";
        s3_region = "garage";
        root_domain = ".s3.garage";
      };
    };
  };
}
