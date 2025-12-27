{
  pkgs,
  ...
}:
{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {

    };
  };
}
