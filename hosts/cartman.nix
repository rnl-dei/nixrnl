{profiles, ...}: {
  imports = with profiles; [
    core.dei
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Servidor de ficheiros do domínio DEIAD";
    createdBy = "dei";
    maintainers = ["dei"];

    uefi = false;
    memory = 10240;
    vcpu = 8;

    interfaces = [
      {
        source = "gia";
        mac = "52:54:00:ac:79:4d";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/volumes/cartman-root";
      }
      {
        source.dev = "/dev/zvol/dpool/data/cartman-data";
      }
    ];
  };
}
