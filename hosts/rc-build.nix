{ profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Builds dos projetos de RC do taguspark";

    uefi = false;
    memory = 4096;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:25:f2:99";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/rc-build"; } ];
  };
}
