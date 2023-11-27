{
  config,
  lib,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    webserver
    phpfpm
    dokuwiki.wiki
  ];

  # Weaver
  services.nginx.virtualHosts.weaver = {
    default = true;
    serverName = "weaver.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
    locations = {
      "/" = {
        root = let
          configFile = pkgs.dashyConfig.weaver;
          dashy = pkgs.dashy.override {inherit configFile;};
        in "${dashy}/share/dashy";
      };
      "~ ^/(doku)?wiki" = {return = "301 $scheme://${config.services.nginx.virtualHosts.wiki.serverName}";};
      "~ ^/raaas" = {return = "301 $scheme://${config.services.nginx.virtualHosts.raaas.serverName}";};
      "~ /zeus(.*)$" = {
        # TODO: Move srx-status-page to a package
        alias = "/var/www/zeus/htdocs/$1";
        extraConfig = ''
          location ~ /zeus/submit {
            alias /var/www/zeus/submit.php;
            fastcgi_pass php;
          }
        '';
      };
    };
  };

  services.phpfpm.pools.default.phpEnv.PATH = lib.makeBinPath [
    # Packages required by SRX-Status-Page (/zeus)
    pkgs.bash
    pkgs.gnumake
    pkgs.gnum4
    pkgs.gawk
    pkgs.coreutils
    pkgs.diffutils
  ];

  # RAaaS
  services.nginx.virtualHosts.raaas = {
    serverName = "raaas.weaver.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
    locations."/".root = "${pkgs.raaas}/share/raaas";
  };

  # Wiki
  services.nginx.virtualHosts.wiki = {
    serverName = "wiki.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
  };

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.weaverIP4 = {
      virtualRouterId = 88;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "193.136.164.88/26";}]; # weaver IPv4
    };
    vrrpInstances.weaverIP6 = {
      virtualRouterId = 88;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "2001:690:2100:81::88/64";}]; # weaver IPv6
    };
  };
}
