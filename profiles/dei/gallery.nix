{
  # lib,
  # pkgs,
  ...
}:
# with lib;
let
  serverName = "eventos.dei.tecnico.ulisboa.pt";
  # required by systemd.
  mediaDir = "/var/lib/private/photoprism";
  port = 2342;
in
{
  # https://nixos.wiki/wiki/PhotoPrism
  # NOTE: Ensure mediaDir and its subfolders (originals, storage) exist before photoprism starts.
  services.nginx.virtualHosts.gallery = {
    inherit serverName;
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString port}";
      proxyWebsockets = true;
    };
  };
  services.photoprism = {
    enable = true;
    originalsPath = "${mediaDir}/originals";
    storagePath = "${mediaDir}/storage";
    passwordFile = "/root/gallery/tmp_pwd"; # FIXME
    settings = {
      #TODO
    };
  };

  # TODO: bindmount - template here.
  # Bind mount /mnt/data/dms to /var/lib/dei/dms/default
  # fileSystems."${config.dei.dms.sites.default.stateDir}" = {
  #   device = "/mnt/data/dms";
  #   options = [ "bind" ];
  # };

}
