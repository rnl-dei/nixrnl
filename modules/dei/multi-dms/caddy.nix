{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
in
{

  services.nginx.defaultListenAddresses = [
    "127.0.0.80"
    # ipv6 has only one loopback address: using only ipv4.
    # https://serverfault.com/questions/193377/ipv6-loopback-addresses-equivalent-to-127-x-x-x
  ];

  systemd.tmpfiles.rules = [
    # TODO: when does this run?
    # what if it runs before the file exists...? :thinking:
    # Make sure temporary selfsigned nixos CA cert is readable by Caddy 
    "z /var/lib/acme/.minica 0755 acme acme -"
    "z /var/lib/acme/.minica/cert.pem 0644 acme acme -"
  ];

  services.caddy = {
    # TODO: remove `package` line on >= 25.11
    # tls_trust_pool directive doesn't seem to exist atm (on 24.05's version)
    package = pkgs.unstable.caddy;
    enable = true;
    acmeCA = config.security.acme.defaults.server;
    inherit (config.security.acme.defaults) email;
    globalConfig = ''
      grace_period 10s
      skip_install_trust
      default_bind ${hostv4} [${hostv6}] #TODO: see comment at `hostv4`/6
    '';

    # Eventually, make a real entry for production/master (or just let nginx keep handling it?)
    # Note: the order of the handle directives matter!
    # The first handle directive that matches will win.
    virtualHosts =
      {
        # Gateway to redirect fenix oauth responses to correct DMS instance
        "fenix-dms-gw.blatta.rnl.tecnico.ulisboa.pt".extraConfig = ''
          encode zstd gzip
          handle {
            redir {header.Referer}login?{query}
          }
        '';
      }
      // (mapAttrs' (
        _vhostName: vhostConfig:
        let
          #TODO: maybe explicitly set serverName for 'localhost' virtualHost (see changes made in webserver.nix) rather than doing this
          svName =
            if (vhostConfig.serverName != null) then
              vhostConfig.serverName
            else
              "dummy-value-for-localhost.blatta.rnl.tecnico.ulisboa.pt"; # TODO: don't know what's the best way to do this
        in
        {
          #name = vhostConfig.serverName ? "dms.blatta.rnl.tecnico.ulisboa.pt";
          name = svName;
          # https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#https
          value = {
            extraConfig = ''
              encode zstd gzip
              reverse_proxy https://127.0.0.80 {
                transport http {
                  tls_server_name ${svName}
                  tls_trust_pool file {
                    pem_file /var/lib/acme/.minica/cert.pem /etc/ssl/certs/ca-bundle.crt
                  }
                }
              }
            '';
          };
        }
      ) config.services.nginx.virtualHosts);
  };
}
