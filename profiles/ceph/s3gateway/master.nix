{
  config,

  ...
}:
{
  config = {
    services.nginx = {
      enable = false;
      virtualHosts = {
        "s3.rnl.tecnico.ulisboa.pt" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://localhost:80";
          };
        };
      };
    };
    environment.etc = {
      "etc/keepalived/keepalived.conf.test" = {
        mode = "644";
        text = ''
          vrrp_instance VI_1 {
              state MASTER
              interface br0
              virtual_router_id 101
              priority 150
              advert_int 1
              authentication {
                  auth_type PASS
                  auth_pass Humiliate-Simple1-Douche-Collision
              }
              virtual_ipaddress {
                  193.136.164.35/26 dev public
              }
              virtual_routes {
                  default via 193.136.164.62 dev public
              }
          }

        '';

      };
    };
  };
}
