{
  pkgs,
  lib,
  config,
  profiles,
  ...
}:
let
  motd = "PLACEHOLDER FTP";
in
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    webserver
    mirrors.mxlinux.isos
  ];

  rnl.labels.location = "neo";

  rnl.virtualisation.guest = {
    description = "VM for supporting ftp transition";
    createdBy = "vasco.petinga";

    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "dmz";
        mac = "17:5e:54:fe:ec:52";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/ftp-vm"; } ];
  };

  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "193.136.164.178";
        prefixLength = 26;
      }
    ];

    defaultGateway.address = "193.136.164.190";
  };

  environment.systemPackages = [ pkgs.ftpsync ];

  users.motd = motd;

  rnl.ftp-server = {
    enable = true;
    motd = builtins.toFile "motd" motd;
  };

  rnl.githook = {
    enable = true;
    hooks.ftp-site = {
      url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/ftp-site.git";
      directoryMode = "755";
    };
  };

  # TODO: Might not work
  systemd.services."remake-ftp-site" = {
    description = "Remake FTP homepage";
    startAt = "*-*-* 02:14:00";
    path = [
      pkgs.bash
      pkgs.gnum4
      pkgs.gnumake
      pkgs.gawk
      (pkgs.python3.withPackages (ps: [
        ps.jinja2
        ps.pyyaml
      ]))
    ];
    script = ''
      #!/usr/bin/env bash
      cd ${config.rnl.githook.hooks.ftp-site.path}
      make
    '';
  };

  systemd.tmpfiles.rules = [ "d /root/.ssh 0755 root root" ];
  age.secrets."root-at-ftp-vm-ssh.key" = {
    # HACK: The root-at-ftp-ssh-key is same as host key. GENERATE NEW ONE
    file = ../secrets/root-at-ftp-vm-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  services.nginx.virtualHosts.ftp = {
    default = true;
    serverName = lib.mkDefault "${config.networking.fqdn}";
    root = config.rnl.githook.hooks.ftp-site.path + "/htdocs";
    # FIXME: Configure firewall to enable ACME
    #enableACME = true;
    #addSSL = true;
    extraConfig = ''
      autoindex on;
      autoindex_exact_size off;
    '';

    locations = {
      "~ ^/pub" = {
        alias = config.rnl.ftp-server.rootDirectory + "/";
      };
      "~ ^/debian" = {
        alias = "/mnt/data/ftp/pub/debian/";
      }; # Recommended by Debian

      "~ ^/dei" = {
        alias = "/mnt/data/ftp/dei/";
      };
      # # TODO: We probably want to add /dei-share with password protection
      # TODO: test later
      # "~ ^/labs" = {
      #   alias = "/mnt/data/ftp/labs/";
      #   extraConfig = ''
      #     autoindex off;
      #     location ~ ^/labs/(windows|software) {
      #       autoindex on;
      #       allow 193.136.164.192/27; # admin v4
      #       allow 2001:690:2100:82::/64; # admin v6
      #       allow 193.136.154.0/25; # labs v4
      #       allow 193.136.154.128/26;# labs2 v4
      #       allow 2001:690:2100:84::/64; # labs v6
      #       deny all;
      #     }
      #   '';
      # };

      # Public but not listed, to share temporary files
      "~ ^/tmp" = {
        alias = "/mnt/data/ftp/tmp/";
        extraConfig = "autoindex off;";
      };
      # TODO: check addresses and stuff
      "~ ^/priv" = {
        alias = "/mnt/data/ftp/priv/";
        extraConfig = ''
          # Allow access only from the RNL networks
          allow 193.136.164.0/24;
          allow 193.136.154.0/24;
          allow 10.16.80.0/24;
          allow 2001:690:2100:80::/58;
          deny all;
        '';
      };
    };
  };
}
