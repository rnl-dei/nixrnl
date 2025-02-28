{ config, pkgs, ... }:
{
  age.secrets."hedgedoc-fenix-api" = {
    file = ../secrets/hedgedoc-fenix-api.age;
    owner = "hedgedoc";
  };

  #decrypted = pkgs.agenix.decryptFile config.age.secrets."hedgedoc-fenix-api".path;
  environment.etc."hedgedoc.env".text = ''
    CMD_PORT=3000
    CMD_DOMAIN=hedgedoc.rnl.tecnico.ulisboa.pt
    CMD_HOST=localhost
    CMD_ALLOW_EMAIL_REGISTER=false
    CMD_EMAIL=false
    CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR=username
    CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR=displayName
    CMD_OAUTH2_TOKEN_URL=https://fenix.tecnico.ulisboa.pt/oauth/access_token
    CMD_OAUTH2_AUTHORIZATION_URL=https://fenix.tecnico.ulisboa.pt/oauth/userdialog
    CMD_OAUTH2_CLIENT_ID=288540197912778
    CMD_OAUTH2_PROVIDERNAME=Fénix
    CMD_OAUTH2_CLIENT_SECRET=@secret@
  '';

  system.activationScripts."hedgedoc-fenix-api" = ''
    secret=$(cat "${config.age.secrets."hedgedoc-fenix-api".path}")
    configFile=/etc/hedgedoc.env
    ${pkgs.gnused}/bin/sed -i "s#@secret@#$secret#" "$configFile"
  '';

  services.hedgedoc = {
    enable = true;
    environmentFile = "/etc/hedgedoc.env";
  };
}
