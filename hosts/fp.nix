{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Projetos de FP LEIC";
    createdBy = "nuno.alves";
    maintainers = ["alberto.abad"];

    memory = 4096;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:51:b3:11";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/data/fp";
      }
    ];
  };
}
