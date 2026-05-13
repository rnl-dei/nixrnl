{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  mailDomain = "comsat-nix.rnl.tecnico.ulisboa.pt";

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

  rawContent = builtins.readFile (
    pkgs.runCommand "decrypt"
      {
        nativeBuildInputs = [ pkgs.rage ];
      }
      ''
        rage --decrypt ${../secrets/email-users.age} -i /etc/ssh/ssh_host_ed25519_key > $out
      ''
  );

  # Split into lines, filtering out empty ones
  lines = builtins.filter (s: s != "") (lib.splitString "\n" rawContent);

  # Transform the list of lines into the attribute set SNM expects
  generatedAccounts = builtins.listToAttrs (
    builtins.filter (x: x != null) (builtins.map extractUser lines)
  );
in
{

  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  age.secrets.users = {
    file = ../secrets/email-users.age;
    mode = "600";
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx.virtualHosts.${config.mailserver.fqdn}.enableACME = true;

  mailserver = {
    enable = true;
    # stateVersion = 4;
    fqdn = "comsat-nix.rnl.tecnico.ulisboa.pt";
    domains = [ mailDomain ];

    certificateScheme = "selfsigned";

    loginAccounts =
      assert builtins.trace "${builtins.toJSON generatedAccounts}" generatedAccounts != null;
      generatedAccounts;

  };
  # security.acme.acceptTerms = true;
}
