{profiles, ...}: {
  imports = with profiles; [
    core.dei
    filesystems.unknown
    os.unknown
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Helios Voting do DEI";
    maintainers = ["dei"];

    uefi = false;
    memory = 4096;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:1f:87:1f";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/helios.img";
      }
    ];
  };
}
