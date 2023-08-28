{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Mooshak para IA/LP";
    maintainers = ["luisa.coheur"];

    uefi = false;
    memory = 2048;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:53:28:53";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/iashak.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/iashak-old.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/iashak-20210405.img";
      }
    ];
  };
}
