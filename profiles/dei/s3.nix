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

    };
  };
}
