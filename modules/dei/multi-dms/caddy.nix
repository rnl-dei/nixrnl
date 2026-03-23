{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  # FIXME: refactor flake for a better way of tracking this (RNL module?)
  cfg = config.dei.multi-dms;
  hostv4 = (builtins.head config.networking.interfaces.enp1s0.ipv4.addresses).address;
  hostv6 = (builtins.head config.networking.interfaces.enp1s0.ipv4.addresses).address;
in
mkIf cfg.enable {

  age.secrets."blatta.cer" = {
    file = ../../../secrets/blatta-cer.age;
    mode = "0400";
    owner = config.services.caddy.user;
    group = config.services.caddy.group;
  };

  age.secrets."blatta.key" = {
    file = ../../../secrets/blatta-key.age;
    mode = "0400";
    owner = config.services.caddy.user;
    group = config.services.caddy.group;
  };

  services.nginx.defaultListenAddresses = [
    "127.0.0.80"
    # ipv6 has only one loopback address: using only ipv4.
    # https://serverfault.com/questions/193377/ipv6-loopback-addresses-equivalent-to-127-x-x-x
  ];

  systemd.tmpfiles.rules = [
    # Make sure temporary selfsigned nixos CA cert is readable by Caddy
    "z /var/lib/acme/.minica 0755 acme acme -"
    "z /var/lib/acme/.minica/cert.pem 0644 acme acme -"
  ];

  services.caddy = {
    # TODO: remove `package` line on >= 24.11
    # `tls_trust_pool` directive doesn't seem to exist atm (on 24.05's version)
    package = pkgs.unstable.caddy;
    enable = true;
    acmeCA = config.security.acme.defaults.server;
    inherit (config.security.acme.defaults) email;
    globalConfig = ''
      grace_period 10s
      skip_install_trust
      default_bind ${hostv4} [${hostv6}] #TODO: see comment at `hostv4`/6
    '';

    # Note: the order of the handle directives matter!
    # The first handle directive that matches will win.
    virtualHosts =
      { }
      // (mapAttrs' (
        _vhostName: vhostConfig:
        let
          svName =
            if (vhostConfig.serverName != null) then
              vhostConfig.serverName
            else
              "dummy-value-for-localhost.blatta.rnl.tecnico.ulisboa.pt"; # don't know if this is the best approach.
          # only for *.blatta.rnl.tecnico.ulisboa.pt and blatta.rnl.tecnico.ulisboa.pt
          # dont know if this best approach
          tlsConfig =
            if (lib.hasSuffix "blatta.rnl.tecnico.ulisboa.pt" svName) then
              "tls ${config.age.secrets."blatta.cer".path} ${config.age.secrets."blatta.key".path}"
            else
              "";
        in
        {
          #name = vhostConfig.serverName ? "dms.blatta.rnl.tecnico.ulisboa.pt";
          name = svName;
          # https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#https
          value = {
            extraConfig = ''
              ${tlsConfig}
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
