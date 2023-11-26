{
  config,
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.nixos
    type.vm

    webserver
    containers.docker
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.11";
          prefixLength = 26;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.62";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:80::11";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:80::ffff:1";
        }
      ];
    };
  };

  rnl.labels.location = "zion";

  # Add dei's keys to root's authorized_keys
  users.users.root.openssh.authorizedKeys.keys = config.users.users.dei.openssh.authorizedKeys.keys;

  services.nginx.virtualHosts.deinew = {
    default = true;
    serverName = lib.mkDefault "deinew.${config.rnl.domain}";
    enableACME = true;
    addSSL = true;
    root = "/var/www";
    locations = {
      "/" = {return = "307 $scheme://dei.rnl.tecnico.ulisboa.pt";};
    };
  };

  # FIXME: Glitchtip is running inside a container, using a docker compose inside of the VM

  services.nginx.upstreams.glitchtip.servers = {
    "127.0.0.1:8000" = {};
  };

  services.nginx.virtualHosts.glitchtip = {
    serverName = lib.mkDefault "glitchtip.deinew.${config.rnl.domain}";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://glitchtip";
      extraConfig = ''
        # RNL IPs
        allow 193.136.164.0/24;
        allow 2001:690:2100:80::/62;

        deny all;
      '';
    };
  };

  rnl.virtualisation.guest = {
    description = "Webserver do DEI";
    createdBy = "nuno.alves";
    maintainers = ["dei"];

    memory = 4096;
    vcpu = 4;

    interfaces = [{source = "pub";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/deinew";}];
  };
}
