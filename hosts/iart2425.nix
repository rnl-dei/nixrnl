{ profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "atlas";

  rnl.virtualisation.guest = {
    description = "VM de IART 2425";
    createdBy = "francisco.martins";
    maintainers = [ "sofia.pinto" ];

    memory = 49152;
    vcpu = 24;
    interfaces = [
      {
        source = "pub";
        mac = "3e:ec:58:74:df:79";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/iart2425"; } ];
  };
}
