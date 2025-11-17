{
  config,
  pkgs,
  ...
}:

let
  secrets-json-path = "/var/lib/immich/immich-config.json";
  pinnedPkgs =
    import
      (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b6a8526";
        sha256 = "sha256-rXXuz51Bq7DHBlfIjN7jO8Bu3du5TV+3DSADBX7/9YQ=";
      })
      {
        system = pkgs.system;
        config = pkgs.config;
      };
in
{
  age.secrets.immich-json = {
    file = ../../secrets/immich-json.age;
    owner = "immich";
    path = secrets-json-path;
  };
  services.immich = {
    enable = true;
    package = pinnedPkgs.immich;
    port = 2283;
    accelerationDevices = null; # this means all btw
    environment = {
      IMMICH_CONFIG_FILE = "/run/agenix/immich-json";
    };
  };

  # Bind mount for persistent storage
  fileSystems."/var/lib/immich" = {
    device = "/mnt/data/immich";
    options = [ "bind" ];
  };

  services.nginx.virtualHosts.immich = {
    serverName = "eventos.dei.tecnico.ulisboa.pt";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   1200s;
            proxy_send_timeout   1200s;
            send_timeout         1200s;

        proxy_request_buffering off; # This 2 buffer options are for disable buffer to large files
            proxy_buffering off;
      '';
    };
  };

  # User setup
  users.users.immich = {
    extraGroups = [
      "video"
      "render"
    ];
  };
}
