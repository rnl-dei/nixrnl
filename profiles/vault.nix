{
  config,
  lib,
  pkgs,
  ...
}: {
  # Configure Hashicorp Vault
  services.vault = {
    enable = true;
    package = pkgs.vault-bin; # This package includes the UI
    extraConfig = lib.mkDefault ''
      ui = true
    '';
    telemetryConfig = lib.mkDefault ''
      prometheus_retention_time = "240h"
      disable_hostname = true
    '';
    storageBackend = lib.mkDefault "mysql";
    # Add storage configuration at the host
  };

  services.nginx.upstreams.vault.servers = {
    "${config.services.vault.address}" = {};
  };

  services.nginx.virtualHosts.vault = {
    serverName = lib.mkDefault "${config.networking.fqdn}";
    # FIXME: This should be enabled when the CA is ready
    #enableACME = true;
    #addSSL = true;
    locations."/" = {
      proxyPass = "http://vault";
    };
  };

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.vaultIP4 = {
      virtualRouterId = 81;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "193.136.164.81/26";}]; # www IPv4
    };
    vrrpInstances.vaultIP6 = {
      virtualRouterId = 81;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "2001:690:2100:81::81/64";}]; # www IPv6
    };
  };
}
