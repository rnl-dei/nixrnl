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
    CMD_ALLOW_ANONYMOUS=false
    CMD_GITLAB_BASEURL=https://gitlab.rnl.tecnico.ulisboa.pt
    CMD_GITLAB_CLIENTID=96efa89c100470dfea13880ad599317d98da78e7ef15fe0946a91ce6a070a606
    CMD_GITLAB_CLIENTSECRET=@secret@

    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt
  '';

  system.activationScripts."hedgedoc-gitlab-api" = ''
    secret=$(cat "${config.age.secrets."hedgedoc-gitlab-api".path}")
    configFile=/etc/hedgedoc.env
    ${pkgs.gnused}/bin/sed -i "s#@secret@#$secret#" "$configFile"
  '';

  services.hedgedoc = {
    enable = true;
    environmentFile = "/etc/hedgedoc.env";
  };
}
