{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Domain Controller do domínio WINRNL";

    uefi = false;
    memory = 8192;
    vcpu = 8;

    interfaces = [
      {
        source = "labs";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/order.img";
      }
    ];
  };
}
