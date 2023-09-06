{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Servidor share DFS do domínio WINRNL";

    uefi = false;
    memory = 8192;
    vcpu = 8;

    interfaces = [
      {
        source = "labs";
        mac = "52:54:00:b5:a5:c3";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/mike.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/lvm/mike_dfs.img";
      }
    ];
  };
}
