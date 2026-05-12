{ config, lib, ... }:

let
  mailDomain = "teste.rnl.tecnico.ulisboa.pt";

  extractUser =
    input:
    let
      parts = builtins.match "([^:]+):(.*)" input;
    in
    if parts == null then
      null
    else
      {
        name = "${builtins.elemAt parts 0}@${mailDomain}";
        value = {
          hashedPassword = builtins.elemAt parts 1;
        };
      };

  secretPath = config.age.secrets.users.path;

  rawContent = if builtins.pathExists secretPath then builtins.readFile secretPath else "";

  # Split into lines, filtering out empty ones
  lines = builtins.filter (s: s != "") (lib.splitString "\n" rawContent);

  # Transform the list of lines into the attribute set SNM expects
  generatedAccounts = builtins.listToAttrs (
    builtins.filter (x: x != null) (builtins.map extractUser lines)
  );

in
{
  age.secrets.users = {
    file = ../secrets/email-users.age;
    mode = "600";
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx.virtualHosts.${config.mailserver.fqdn}.enableACME = true;

  mailserver = {
    enable = true;
    stateVersion = 4;
    fqdn = "comsat-nix.rnl.tecnico.ulisboa.pt";
    domains = [ mailDomain ];

    x509.useACMEHost = config.mailserver.fqdn;

    accounts = generatedAccounts;
  };
}
