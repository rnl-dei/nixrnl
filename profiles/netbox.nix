{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Use unstable for the latest version of netbox
  imports = [ (inputs.unstable + "/nixos/modules/services/web-apps/netbox.nix") ];
  disabledModules = [ "services/web-apps/netbox.nix" ];

  services.netbox = {
    enable = true;
    package = pkgs.unstable.netbox;
    plugins = py3Pkgs: with py3Pkgs; [ ];
    settings = {
      ADMINS = [
        [
          "RNL"
          "robots@${config.rnl.domain}"
        ]
      ];

      REMOTE_AUTH_BACKEND = "social_core.backends.gitlab.GitLabOAuth2";
      SOCIAL_AUTH_API_URL = "https://gitlab.rnl.tecnico.ulisboa.pt";
      SOCIAL_AUTH_REDIRECT_IS_HTTPS = true;
    };
  };

  security.sudo.enable = lib.mkForce true; # Required to run netbox-manage

  services.nginx.upstreams.netbox.servers = {
    "${config.services.netbox.listenAddress}:${toString config.services.netbox.port}" = { };
  };
  services.nginx.virtualHosts.netbox = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".proxyPass = "http://netbox";
      "/static/".alias = "${config.services.netbox.dataDir}/static/";
    };
  };
  users.users.nginx.extraGroups = [ "netbox" ]; # Allow nginx to read netbox files
}
