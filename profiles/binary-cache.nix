{
  config,
  lib,
  ...
}: {
  # Generate a public/private key pair like this:
  # $ nix-store --generate-binary-cache-key cache.yourdomain.tld-1 /var/lib/secrets/harmonia.secret /var/lib/secrets/harmonia.pub
  services.harmonia.enable = true;
  nix.settings.allowed-users = ["harmonia"];

  services.nginx.virtualHosts.binary-cache = {
    serverName = lib.mkDefault "binary-cache.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".extraConfig = ''
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        zstd on;
        zstd_types application/x-nix-archive;
      '';
    };
  };
}
