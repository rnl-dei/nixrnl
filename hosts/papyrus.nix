{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    mattermost.papyrus
    webserver
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.7";
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
          address = "2001:690:2100:80::7";
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

  # TODO: Add wheatley bot

  # Bind mount /var/lib/mattermost to /mnt/data/mattermost
  fileSystems."${config.services.mattermost.statePath}" = {
    device = "/mnt/data/mattermost";
    options = ["bind"];
  };

  rnl.labels.location = "chapek";

  rnl.storage.disks.data = ["/dev/vdb"];

  rnl.virtualisation.guest = {
    description = "Servidor de comunicação interna";

    interfaces = [{source = "pub";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/papyrus";}
      {source.dev = "/dev/zvol/dpool/data/papyrus";}
    ];
  };
}
