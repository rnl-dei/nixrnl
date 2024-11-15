{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kea ];
  # Kea Config
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      subnet4 = [
        {
          pools = [ { pool = "10.16.80.5-10.16.80.250"; } ];
          subnet = "10.16.80.0/23";
        }
      ];
      valid-lifetime = 600;
      max-valid-lifetime = 3600;
      interfaces-config = {
        interfaces = [ "enp1s0" ];
      };
      option-data = [
        {
          name = "domain-name-servers";
          code = 6;
          data = "193.136.164.1";
        }
        {
          name = "domain-name";
          code = 15;
          data = "rnl.tecnico.ulisboa.pt";
        }
      ];
    };
  };
}
