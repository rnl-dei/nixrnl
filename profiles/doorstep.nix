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
      valid-lifetime = 4000;
      option-data = [
        {
          name = "DNS servers";
          data = "ns.rnl.tecnico.ulisboa.pt";
        }
      ];
    };
  };
}
