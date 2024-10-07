{ profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.unknown
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Website do museu do DEI";
    createdBy = "nuno.alves";
    maintainers = [ "david.matos" ];

    memory = 8192;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:40:cb:23";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/museu"; } ];
  };
}
