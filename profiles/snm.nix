{
  config,
  inputs,
  pkgs,
  ...
}:
# Outline:
# secret in format USER:PASSWORD will be deployed by agenix
# systemd service will given that file, create USER-secret, which will contain only the hashed password
# the nix module will have a map that given [users] will point user.HashedPasswordFile to USER-secret
# Note that for adding new users its gonna be:
# - add user to secrets
# - add user to nix user list
let
  mailDomain = "comsat-nix.rnl.tecnico.ulisboa.pt";
  secretsTarget = "/run/secrets/";
  script = pkgs.writeShellScript "create-hashed-password-file" ''
    set -euo pipefail
    TARGET=${secretsTarget}
    SECRET=${config.age.secrets.users.path}
    rm -rf $TARGET
    mkdir -p $TARGET
    awk -F: -v target="$TARGET" '{ print $2 > (target "/" $1) }' "$SECRET"

    chmod 400 "$TARGET"/*
    chown root:dovecot2 "$TARGET"/*
  '';
  #FIXME: alternative?
  users = [
    "antonia"
    "carlos"
    "filipe"
    "iglesias"
    "luis"
    "marco"
    "miguel"
    "nuba"
    "nuno"
    "pedro"
    "pjvenda"
    "pombo"
    "tiago"
    "vilhena"
    "taveira"
    "dumiense"
    "ricardo"
    "jose"
    "pedro.ribeiro"
    "anog"
    "luis.cunha"
    "nagios"
    "braulio.silva"
    "israel.lugo"
    "tiago.pereira"
    "joao.matos"
    "guilherme.andrade"
    "samuel.bernardo"
    "andre.aparicio"
    "andre.nunes"
    "fernando.cesar"
    "historico"
    "rodrigo.bruno"
    "jose.pedro.arvela"
    "tomas.pinho"
    "goncalo.rodrigues"
    "andre.dias"
    "nuno.silva"
    "luis.espirito.santo"
    "jorge.heleno"
    "miguel.amaral"
    "lurdes.farrusco"
    "rodrigo.rato"
    "tomas.cunha"
    "rui.ribeiro"
    "henrique.santos"
    "andre.breda"
    "bernardo.conde"
    "leicalumni"
    "dora.lourenco"
    "marcelo.santos"
    "pedro.maximino"
    "carlos.vaz"
    "joao.borges"
    "luis.fonseca"
    "nuno.alves"
    "diogo.cardoso"
    "gitlab-incoming"
    "vasco.correia"
    "martim.monis"
    "dmarc"
    "mateus.pinho"
    "andre.romao"
    "vasco.morais"
    "francisco.martins"
    "tiago.caixinha"
    "vasco.petinga"
    "kutt"
    "hugo.vicente"
    "hikvision"
    "simao.lavos"
  ];
  hashedPasswords = builtins.listToAttrs (
    map (user: {
      name = "${user}@${mailDomain}";
      value = {
        hashedPasswordFile = "${secretsTarget}/${user}";
      };
    }) users
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

  # TODO: maybe sandbox this
  systemd.services.snm-createHashedPasswordFile = {
    enable = true;
    before = [ "dovecot2.service" ];
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
    path = [
      pkgs.coreutils
      pkgs.gawk
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = script;
      User = "root";
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx.virtualHosts.${config.mailserver.fqdn}.enableACME = true;

  mailserver = {
    enable = true;
    # stateVersion = 4;
    fqdn = "comsat-nix.rnl.tecnico.ulisboa.pt";
    domains = [ mailDomain ];

    certificateScheme = "selfsigned";

    loginAccounts = hashedPasswords;
  };
  # security.acme.acceptTerms = true;
}
