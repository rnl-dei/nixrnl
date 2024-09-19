{
  config,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.zfs-mirror
    os.nixos
    type.physical

    binary-cache
    proxy-cache
    webserver
    transmission.labs
  ];

  rnl.labels.location = "inf1-p2-c1";

  # Storage
  rnl.storage.disks.root = [
    "/dev/disk/by-id/ata-WDC_WD1002FAEX-00Y9A0_WD-WCAW34582499"
    "/dev/disk/by-id/ata-WDC_WD10EZEX-00RKKA0_WD-WCC1S3606587"
  ];

  rnl.internalHost = true;

  # Networking
  networking = {
    hostId = "b0234a5e";

    interfaces.enp0s31f6 = {
      ipv4.addresses = [
        {
          address = "193.136.154.116";
          prefixLength = 25;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:84::8000:116";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.154.126";
    defaultGateway6.address = "2001:690:2100:84:ffff:ffff:ffff:1";
  };

  users.users.root.hashedPassword = "$6$FYer1DJhVX1eYtCx$/gMyf.WtjzxE/KyeGaHPLeeJN2.mMkCsPuKBGkCGlpxmhnJrh7nbqj.97aLmMM9vLpjWFj7FWkmNT9Q4jAlRG1";

  age.secrets."dollars-binary-cache-key" = {
    file = ../secrets/dollars-binary-cache-key.age;
    owner = "harmonia";
    group = "harmonia";
  };

  services.harmonia.signKeyPath = config.age.secrets."dollars-binary-cache-key".path;

  services.nginx.virtualHosts.binary-cache.serverName = "labs.cache.rnl.tecnico.ulisboa.pt";
  services.nginx.virtualHosts.proxy-cache.serverName = "proxy.cache.rnl.tecnico.ulisboa.pt";
}
