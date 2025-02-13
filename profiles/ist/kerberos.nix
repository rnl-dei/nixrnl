{ pkgs, ... }:
{
  # Setup Kerberos
  security.krb5 = {
    enable = true;
    settings = {
      libdefaults = {
        default_realm = "IST.UTL.PT";
        dns_fallback = true;
        forwardable = true;

        # Required for SSH authentication into sigma
        dns_canonicalize_hostname = true;
        rnds = true;
      };

      realms = {
        "IST.UTL.PT" = {
          default_domain = "kerberos.tecnico.ulisboa.pt";
        };
      };
    };
  };

  programs.ssh.package = pkgs.openssh_gssapi;
}
