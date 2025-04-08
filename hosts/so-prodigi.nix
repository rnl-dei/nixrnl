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
    createdBy = "francisco.martins";
    maintainers = [ "miguel.pardal" ];

    memory = 16384;

    interfaces = [
      {
        source = "priv";
        mac = "52:54:00:51:b3:11";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/fp"; } ];
  };
}
