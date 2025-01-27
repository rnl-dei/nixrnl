{ config, lib, ... }:
let
  defaultACMEServer = lib.mkIf config.rnl.internalHost "${config.rnl.vault.url}/v1/pki/acme/directory";
in
{
  # DHParams (Enable if you want to use DHE)
  security.dhparams = {
    defaultBitSize = 2048; # Recommended value
  };

  # ACME
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "robots@${config.rnl.domain}";
      server = defaultACMEServer;
    };
    certs = lib.mkDefault {
      "${config.networking.fqdn}" = {
        extraDomainNames = lib.mkIf (config.networking.domain == config.rnl.domain) [
          "${config.networking.hostName}.rnl.ist.utl.pt"
        ];
      };
    };
  };
}
