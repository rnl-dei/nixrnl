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
    description = "VM ubuntu de apoio ao PIC2 do nuno.alves (ex-rnl)";
    createdBy = "vasco.morais";
    maintainers = [ "nuno.alves" ];

    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "pub";
        mac = "7e:cd:ad:ed:61:c0";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/yang"; } ];
  };
}
