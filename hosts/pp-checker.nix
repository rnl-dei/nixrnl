{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Checker para projetos de Procura e Planeamento";
    createdBy = "diogo.cardoso";
    maintainers = ["ines.lynce" "david.pissarra"];

    vcpu = 4;
    memory = 4096;

    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/pp-checker";}];
  };
}
