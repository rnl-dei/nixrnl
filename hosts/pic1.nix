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
    description = "VM de Pic";
    createdBy = "francisco.martins";
    maintainers = [ "nuno.lopes" ];

    memory = 131072;
    vcpu = 32;
    interfaces = [
      {
        source = "pub";
        mac = "52:54:00:51:b3:11";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/pic1"; } ];
  };
}
