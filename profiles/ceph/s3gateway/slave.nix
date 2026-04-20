{
  ...
}:
{
  config = {
    services.nginx = {
      enable = true;
      virtualHosts = {
        "s3.rnl.tecnico.ulisboa.pt" = {
          forceSSL = true;
          sslCertificate = "/etc/ssl/shared_certs/ssl_cert.crt";
          sslCertificateKey = "/etc/ssl/shared_certs/ssl_cert.key";
          locations."/" = {
            proxyPass = "http://localhost:7480";
            extraConfig = ''
              client_max_body_size 50000M;
            '';
          };
        };
      };
    };
    environment.etc = {
      "keepalived/keepalived.conf" = {
        mode = "644";
        text = ''
          vrrp_instance VI_1 {
              state BACKUP
              interface br0
              virtual_router_id 101
              priority 140
              advert_int 1
              authentication {
                  auth_type PASS
                  auth_pass Humiliate-Simple1-Douche-Collision
              }
              virtual_ipaddress {
                  193.136.164.35/26 dev pub
              }
              virtual_routes {
                  default via 193.136.164.62 dev pub
              }
          }

        '';

      };
    };
  };
}
