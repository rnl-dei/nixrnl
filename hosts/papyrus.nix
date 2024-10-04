{
  config,
  profiles,
  pkgs,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    mattermost.papyrus
    webserver
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.7";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:80::7";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.62";
    defaultGateway6.address = "2001:690:2100:80::ffff:1";
  };

  # Bind mount /mnt/data/mattermost to /var/lib/mattermost
  fileSystems."${config.services.mattermost.statePath}" = {
    device = "/mnt/data/mattermost";
    options = [ "bind" ];
  };

  rnl.db-cluster = {
    ensureDatabases = [ "mattermost" ];
    ensureUsers = [
      {
        name = "mattermost";
        ensurePermissions = {
          "mattermost.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Wheatley Bot
  rnl.wheatley = {
    enable = true;
    instances.default = {
      mattermost.url = config.services.mattermost.siteUrl;
      mattermost.tokenFile = config.age.secrets."papyrus-wheatley.token".path;
      configFile = "${config.rnl.githook.hooks.wheatley-config.path}/config.yml";
    };
  };

  rnl.githook = {
    enable = true;
    hooks.wheatley-config = {
      url = "git@gitlab.rnl.tecnico.ulisboa.pt:/rnl/wheatley-config.git";
      path = "/etc/wheatley";
      directoryMode = "0755";
      hookScript = pkgs.writeText "wheatley-config-hook" ''
        # TODO: This should be done in githook
        ${pkgs.git}/bin/git pull origin master
        ${pkgs.systemdMinimal}/bin/systemctl restart wheatley.service
      '';
    };
  };

  age.secrets."root-at-papyrus-ssh.key" = {
    file = ../secrets/root-at-papyrus-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
  };

  age.secrets."papyrus-wheatley.token" = {
    file = ../secrets/papyrus-wheatley-token.age;
    owner = config.rnl.wheatley.user;
  };

  rnl.labels.location = "chapek";

  rnl.storage.disks.data = [ "/dev/vdb" ];

  rnl.virtualisation.guest = {
    description = "Servidor de comunicação interna";

    interfaces = [ { source = "pub"; } ];
    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/papyrus"; }
      { source.dev = "/dev/zvol/dpool/data/papyrus"; }
    ];
  };
}
