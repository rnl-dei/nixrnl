{
  config,
  lib,

  ...
}:
{
  options = {
    s3.ismaster = lib.mkOption {
      type = lib.types.bool;
      description = "Is master";
      default = false;
    };
  };
  config = {
    security.acme.acceptTerms = true;
    services.nginx = {
      enable = true;
      virtualHosts = {
        "s3.rnl.tecnico.ulisboa.pt" = {
          forceSSL = true;
          enableACME = true;
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
          AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
        '';

      };
    };
  };
}
