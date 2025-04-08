{ profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "dredd";

  rnl.virtualisation.guest = {
    description = "VM de Introdução a SO Prodigi";
    createdBy = "nuno.alves";
    maintainers = [ "alberto.abad" ];

    memory = 6144;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:51:b3:11";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/fp"; } ];
  };
}
