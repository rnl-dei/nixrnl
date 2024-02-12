{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Worker do sistema Rates - Tese do André Marinho";
    createdBy = "diogo.cardoso";
    maintainers = ["andre.marinho"];

    autostart = false;
    memory = 4096;
    vcpu = 4;

    interfaces = [{source = "dmz";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/rates-worker";}];
  };
}
