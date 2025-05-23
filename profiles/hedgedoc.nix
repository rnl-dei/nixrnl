{ config, pkgs, ... }:
{
  age.secrets."hedgedoc-fenix-api" = {
    file = ../secrets/hedgedoc-fenix-api.age;
    owner = "hedgedoc";
  };

  #decrypted = pkgs.agenix.decryptFile config.age.secrets."hedgedoc-fenix-api".path;
  environment.etc."hedgedoc.env".text = ''
    NODE_ENV=production
    CMD_PROTOCOL_USESSL=true
    CMD_PORT=3000
    CMD_DOMAIN=hedgedoc.rnl.tecnico.ulisboa.pt
    CMD_HOST=localhost
    CMD_ALLOW_EMAIL_REGISTER=false
    CMD_EMAIL=true
    CMD_ALLOW_ANONYMOUS=false
    CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR=username
    CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR=username
    CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR=email
    CMD_OAUTH2_TOKEN_URL=https://fenix.tecnico.ulisboa.pt/oauth/access_token
    CMD_OAUTH2_AUTHORIZATION_URL=https://fenix.tecnico.ulisboa.pt/oauth/userdialog
    CMD_OAUTH2_CLIENT_ID=288540197912778
    CMD_OAUTH2_PROVIDERNAME=Fénix
    CMD_OAUTH2_CLIENT_SECRET=@secret@
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt
    CMD_OAUTH2_SCOPE=openid email profile
    CMD_OAUTH2_USER_PROFILE_URL=https://fenix.tecnico.ulisboa.pt/api/fenix/v1/person
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
