{ config, ... }:
{

  # https://letsencrypt.org/repository/#let-s-encrypt-subscriber-agreement
  security.acme.acceptTerms = true;

  # Allow incoming HTTP connections
  networking.firewall.allowedTCPPorts = [ 80 ];

  # Enable ACME HTTP-01 challenge with nginx
  services.nginx.virtualHosts.${config.mailserver.fqdn}.enableACME = true;

  mailserver = {
    enable = true;
    stateVersion = 4;
    fqdn = "mail.rnl.tecnico.ulisboa.pt";
    domains = [ "rnl.tecnico.ulisboa.pt" ];

    # Reference the existing ACME configuration created by nginx
    x509.useACMEHost = config.mailserver.fqdn;

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -s'
    accounts = {
      "user1@example.com" = {
        # Reads the password hash from a file on the server
        hashedPasswordFile = "/a/file/containing/a/hashed/password";

        # Additional addresses delivered to this mailbox
        aliases = [ "postmaster@example.com" ];
      };
      "user2@example.com" = {
        # Provides the password hash inline
        hashedPassword = "$y$j9T$JqqefR6flaaJBRjD4KVZc1$QM6h4Spr5.yn/FuIT.ydTV22daEbiVd8ZprV/POtPgB";
      };
    };
  };
}
