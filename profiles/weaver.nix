{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
let
  docsWebsitePort = 3000;
in
{
  imports = with profiles; [
    webserver
    phpfpm
    dokuwiki.wiki
    containers.docker
  ];

  age.secrets."container-weaver-deploy-token".file = ../secrets/container-weaver-deploy-token.age;

  # Weaver
  services.nginx.virtualHosts.weaver = {
    default = true;
    serverName = "weaver.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
    locations = {
      "/" = {
        root =
          let
            configFile = pkgs.dashyConfig.weaver;
            dashy = pkgs.dashy.override { inherit configFile; };
          in
          "${dashy}/share/dashy";
      };
      "~ ^/(doku)?wiki([^\\r\\n]*)$" = {
        return = "301 $scheme://${config.services.nginx.virtualHosts.wiki.serverName}$2$is_args$args";
      };
      "~ ^/raaas" = {
        return = "301 $scheme://${config.services.nginx.virtualHosts.raaas.serverName}";
      };
      "~ ^/zeus(.*)$" = {
        # TODO: Move srx-status-page to a package
        alias = "/var/www/zeus/htdocs/$1";
        extraConfig = ''
          location ~ ^/zeus/submit {
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

  # Watchtower
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    environment = {
      "WATCHTOWER_LABEL_ENABLE" = "true"; # Filter containers by label "com.centurylinklabs.watchtower.enable"
      "WATCHTOWER_POLL_INTERVAL" = "300"; # 5 minutes
    };
  };

  # RAaaS
  services.nginx.virtualHosts.raaas = {
    serverName = "raaas.weaver.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
    locations."/".proxyPass = "http://localhost:3000";
  };

  virtualisation.oci-containers.containers."raaas" = {
    image = "registry.rnl.tecnico.ulisboa.pt/rnl/raaas:latest";
    ports = [ "3000:80" ];
    labels = {
      "com.centurylinklabs.watchtower.enable" = "true";
    };
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
      virtualIps = [ { addr = "193.136.164.88/26"; } ]; # weaver IPv4
    };
    vrrpInstances.weaverIP6 = {
      virtualRouterId = 88;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [ { addr = "2001:690:2100:81::88/64"; } ]; # weaver IPv6
    };
  };

  # Documentation
  services.nginx.virtualHosts."docs" = {
    serverName = "docs.rnl.tecnico.ulisboa.pt";
    enableACME = true;
    forceSSL = true;
    locations = {
      "/".proxyPass = "http://localhost:${toString docsWebsitePort}";
    };
  };

  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    environment = {
      "WATCHTOWER_LABEL_ENABLE" = "true"; # Filter containers by label "com.centurylinklabs.watchtower.enable"
      "WATCHTOWER_POLL_INTERVAL" = "300"; # 5 minutes
    };
  };

  virtualisation.oci-containers.containers."docs-website" = {
    image = "registry.rnl.tecnico.ulisboa.pt/dei/dei-rnl-docs:latest";
    login = {
      registry = "registry.rnl.tecnico.ulisboa.pt";
      username = "weaver";
      passwordFile = config.age.secrets."container-weaver-deploy-token".path;
    };
    ports = [ "${toString docsWebsitePort}:80" ];
    labels = {
      "com.centurylinklabs.watchtower.enable" = "true";
    };
  };
}
