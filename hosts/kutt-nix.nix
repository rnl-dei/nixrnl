{
  profiles,
  ...
}:
let
  kutt_state_dir = "/var/lib/kutt";
  kutt_port = 3000;
in
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
    webserver
    containers.docker
    kutt
    # future kutt profile here
  ];

  rnl.labels.location = "atlas";

  rnl.storage.disks.data = [ "/dev/vdb" ];

  fileSystems."${kutt_state_dir}" = {
    device = "/mnt/data/kutt";
    options = [ "bind" ];
  };

  rnl.virtualisation.guest = {
    description = "URL shortener da RNL - nix version";
    createdBy = "vasco.petinga";

    memory = 6144;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "9e:cf:07:d1:8e:2d";
      }
    ];
    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/kutt"; }
      { source.dev = "/dev/zvol/dpool/data/kutt"; } # for docker volumes / databases to backup
    ];
  };

  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "193.136.164.176";
        prefixLength = 26;
      }
    ];

    interfaces.enp1s0.ipv6.addresses = [
      {
        address = "2001:690:2100:83::176";
        prefixLength = 64;
      }
    ];
    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";
  };

  services.nginx.virtualHosts = {
    "kutt" = {
      serverName = "s.rnl.pt";
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString kutt_port}";
    };
    "rnl.pt" = {
      serverName = "rnl.pt";
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString kutt_port}";
    };
    "dei.pt" = {
      serverName = "dei.pt";
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString kutt_port}";
    };
    "eventos.dei.pt" = {
      serverName = "eventos.dei.pt";
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString kutt_port}";
    };
    "noticias.dei.pt" = {
      serverName = "noticias.dei.pt";
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString kutt_port}";
    };
  };
}
