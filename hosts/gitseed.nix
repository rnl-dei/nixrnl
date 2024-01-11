{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Avaliação de projetos e laboratórios de IAED";
    createdBy = "nuno.alves";
    maintainers = ["vasco.manquinho"];

    memory = 6144; # 6GB
    vcpu = 8;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:db:1a:ed";
      }
    ];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/gitseed";}];
  };
}
