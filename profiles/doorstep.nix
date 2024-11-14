{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kea ];
  # Kea Config
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      subnet4 = [
        {
          pools = [ { pool = "10.16.80.1-10.16.80.4"; } ];
          subnet = "10.16.80.0/23";
        }
      ];
      valid-lifetime = 4000;
    };
  };
}
