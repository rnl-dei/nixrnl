{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
let
  plugins = with pkgs.moodlePlugins; [
    peerwork
    course_menu
    coderunner
    adaptive_adapted_for_coderunner
    filtercodes
    syntaxhighlighter
    mergeusers
    scheduler
  ];

  # Max upload size
  maxUploadSize = "100M";
in
{
  imports = with profiles; [ webserver ];

  services.moodle = {
    enable = true;
    package = pkgs.moodle.override { inherit plugins; };
    initialPassword = "M00dl3!Admin"; # Don't forget to change this after install
    database = {
      host = lib.mkDefault config.rnl.database.host;
      port = lib.mkDefault config.rnl.database.port;
      createLocally = lib.mkForce false; # Create the database locally does not work
    };
    virtualHost = {
      hostName = lib.mkDefault config.networking.fqdn;
      enableACME = lib.mkDefault true;
      forceSSL = lib.mkDefault true;
    };
  };

  services.phpfpm.pools.moodle = {
    phpOptions = ''
      # Increase the maximum upload size
      upload_max_filesize = ${maxUploadSize}
      post_max_size = ${maxUploadSize}
    '';
    group = lib.mkForce config.services.nginx.group;
  };

  services.nginx.virtualHosts.moodle = {
    default = lib.mkDefault true;
    serverName = config.services.moodle.virtualHost.hostName;
    serverAliases = [ config.networking.fqdn ];
    root = "${config.services.moodle.package}/share/moodle";
    inherit (config.services.moodle.virtualHost)
      enableACME
      forceSSL
      addSSL
      onlySSL
      ;

    extraConfig = ''
      client_max_body_size ${maxUploadSize};
    '';

    locations = {
      "/".index = "index.php";
      "~ [^/]\\.php(/|$)" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_index index.php;
          fastcgi_pass unix:${config.services.phpfpm.pools.moodle.socket};
        '';
        fastcgiParams = {
          SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
          PATH_INFO = "$fastcgi_path_info";
        };
      };
    };
  };
}
