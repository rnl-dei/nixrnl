{
  config,
  lib,
  profiles,
  ...
}:
{
  imports = with profiles; [ certificates ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    enableReload = true;
    serverTokens = false;
    statusPage = true;

    # Enable recommended settings
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    sslDhparam = config.security.dhparams.params.nginx.path;

    # https://github.com/NixOS/nixpkgs/pull/374519
    # NixOS automatically creates a `localhost` virtualhost for Prometheus healthchecks.
    # This virtualhost tries to bind/listen everywhere - force it to use localhost only.
    virtualHosts.localhost.listenAddresses = lib.mkForce [
      "127.0.0.1"
      "[::1]"
    ];
  };

  security.dhparams = {
    enable = true;
    params.nginx = { };
  };

  # Configure nginx exporter
  services.prometheus.exporters.nginx = {
    enable = lib.mkDefault true;
    openFirewall = true;
  };

  # Always use Nginx
  services.httpd.enable = lib.mkForce false;

  # Override the user and group to match the Nginx ones
  # Since some services uses the httpd user and group
  services.httpd = {
    user = lib.mkForce config.services.nginx.user;
    group = lib.mkForce config.services.nginx.group;
  };
}
