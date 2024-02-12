{
  config,
  lib,
  ...
}: {
  services.nginx.virtualHosts.proxy-cache = {
    # serverName = lib.mkDefault "proxy-cache." + config.networking.fqdn;
    serverName = lib.mkDefault "proxy-cache.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations = {
      "~ ^/nix-cache-info".extraConfig = ''
        proxy_store        on;
        proxy_store_access user:rw group:rw all:r;
        proxy_temp_path    /var/cache/nginx/nix-cache-info/temp;
        root               /var/cache/nginx/nix-cache-info/store;

        proxy_set_header Host "cache.nixos.org";
        proxy_pass https://cache.nixos.org;
      '';

      "~ ^/nar/.+$".extraConfig = ''
        proxy_store        on;
        proxy_store_access user:rw group:rw all:r;
        proxy_temp_path    /var/cache/nginx/nar/temp;
        root               /var/cache/nginx/nar/store;

        proxy_set_header Host "cache.nixos.org";
        proxy_pass https://cache.nixos.org;
      '';

      "~ ^/.+.narinfo$".extraConfig = ''
        proxy_store        on;
        proxy_store_access user:rw group:rw all:r;
        proxy_temp_path    /var/cache/nginx/narinfo/temp;
        root               /var/cache/nginx/narinfo/store;

        proxy_set_header Host "cache.nixos.org";
        proxy_pass https://cache.nixos.org;
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/nginx/nix-cache-info           0755 nginx nginx"
    "d /var/cache/nginx/nix-cache-info/temp      0755 nginx nginx"
    "d /var/cache/nginx/nix-cache-info/store     0755 nginx nginx"
    "d /var/cache/nginx/nar                      0755 nginx nginx"
    "d /var/cache/nginx/nar/temp                 0755 nginx nginx"
    "d /var/cache/nginx/nar/store                0755 nginx nginx"
    "d /var/cache/nginx/narinfo                  0755 nginx nginx"
    "d /var/cache/nginx/narinfo/temp             0755 nginx nginx"
    "d /var/cache/nginx/narinfo/store            0755 nginx nginx"
  ];
}
