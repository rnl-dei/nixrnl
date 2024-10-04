{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Domain Controller do domínio WINRNL (Backup)";

    uefi = false;
    memory = 8192;
    vcpu = 8;

    interfaces = [
      {
        source = "labs";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/chaos"; } ];
  };
}
