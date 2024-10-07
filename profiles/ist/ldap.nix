{ pkgs, ... }:
{
  # Setup LDAP
  users.ldap = {
    enable = true;
    base = "dc=ist,dc=utl,dc=pt";
    server = "ldaps://ldap.tecnico.ulisboa.pt";
    nsswitch = false;
    loginPam = false;
  };

  environment.systemPackages = [ pkgs.openldap ];
}
