{ profiles, ... }:
{
  imports = with profiles; [
    core.dei
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Servidor WDS e development para o domínio DEIAD";
    createdBy = "rodrigo.rato";
    maintainers = [ "dei" ];

    uefi = false;
    memory = 8192;
    vcpu = 8;

    interfaces = [
      {
        source = "gia";
        mac = "52:54:00:f9:97:28";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      { source.dev = "/dev/zvol/dpool/data/fry-root"; }
      { source.dev = "/dev/zvol/dpool/data/fry-data"; }
    ];
  };
}
