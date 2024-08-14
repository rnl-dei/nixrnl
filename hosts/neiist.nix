{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Webserver do NEIIST";
    maintainers = ["neiist"];

    uefi = false;
    memory = 4096;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:ef:b5:13";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/neiist.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/lvm/neiist-old.img";
      }
    ];
  };

  rnl.db-cluster = {
    ensureDatabases = ["neiist"];
    ensureUsers = [
      {
        name = "neiist";
        ensurePermissions = {
          "neiist.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
