{
  config,
  profiles,
  pkgs,
  ...
}:
let
  docsWebsitePort = 3000;
in
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    containers.docker
    webserver
    weaver
    netbox
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.89";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::89";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  # Netbox
  services.nginx.virtualHosts.netbox.serverName = "netbox.weaver.${config.rnl.domain}";
  services.netbox = {
    secretKeyFile = config.age.secrets."netbox-weaver-secret.key".path;
    extraConfig = ''
      # Load file
      with open("${config.age.secrets."netbox-weaver-env.py".path}") as f:
        exec(f.read())
    '';
  };

  age.secrets."netbox-weaver-secret.key" = {
    file = ../secrets/netbox-weaver-secret-key.age;
    owner = "netbox";
  };
  age.secrets."netbox-weaver-env.py" = {
    file = ../secrets/netbox-weaver-env-py.age;
    owner = "netbox";
  };

  # Bind mount /var/lib/dokuwiki/wiki/data to /mnt/data/dokuwiki
  fileSystems."${config.services.dokuwiki.sites.wiki.stateDir}" = {
    device = "/mnt/data/dokuwiki/data";
    options = [ "bind" ];
  };
  fileSystems."${config.services.dokuwiki.sites.wiki.usersFile}" = {
    device = "/mnt/data/dokuwiki/users.auth.php";
    options = [ "bind" ];
  };

  rnl.internalHost = true;

  rnl.labels.location = "zion";

  rnl.storage.disks.data = [ "/dev/vdb" ];

  rnl.virtualisation.guest = {
    description = "Webserver interno";

    vcpu = 4;
    memory = 4096;

    interfaces = [ { source = "priv"; } ];
    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/weaver1"; }
      { source.dev = "/dev/zvol/dpool/data/weaver1"; }
    ];
  };

  # Sync wiki pages to GitLab
  systemd.services.dokuwiki-sync-gitlab = {
    description = "Sync DokuWiki pages to GitLab";
    wantedBy = [ "multi-user.target" ];
    startAt = "*-*-* *:00:00"; # Run every hour
    serviceConfig = {
      Type = "oneshot";
      User = "dokuwiki";
      Group = "nginx";
    };
    script = ''
      cd ${config.services.dokuwiki.sites.wiki.stateDir}/pages
      ${pkgs.git}/bin/git pull
      ${pkgs.git}/bin/git add .
      ${pkgs.git}/bin/git commit -m "Sync $(date +%Y-%m-%d_%H-%M-%S)" || true
      ${pkgs.git}/bin/git push
    '';
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
    image = "registry.rnl.tecnico.ulisboa.pt/dei/DEI-RNL-Docs:latest";
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
