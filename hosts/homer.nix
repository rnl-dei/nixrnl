{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Domain Controller do domínio DEIAD";
    maintainers = ["dei"];

    uefi = false;
    autostart = false; # Keep it off until starts working :/
    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "gia";
        mac = "52:54:00:67:b6:8f";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/data/homer";
      }
    ];
  };
}
