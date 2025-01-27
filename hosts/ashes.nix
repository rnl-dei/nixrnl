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
    description = "VM do nuno.silva@rnl (ex-rnl)";
    createdBy = "nuno.silva";
    maintainers = [ "nuno.silva" ];

    uefi = false;
    memory = 2048;
    vcpu = 8;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:f1:03:00";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];

    disks = [ { source.dev = "/dev/zvol/dpool/data/ashes"; } ];
  };
}
