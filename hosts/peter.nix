{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Domain Controller do domínio DEIAD (Backup)";
    maintainers = ["dei"];

    uefi = false;
    autostart = false; # Keep it off until starts working
    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "gia";
        mac = "52:54:00:f9:ff:73";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/data/peter-root";
      }
      {
        source.dev = "/dev/zvol/dpool/data/peter-data";
      }
    ];
  };
}
