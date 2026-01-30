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
    description = "Worker2 do sistema RATES";
    createdBy = "francisco.martins";
    maintainers = [ "luis.macorano" ];

    memory = 4096;
    vcpu = 5;

    interfaces = [
      {
        source = "dmz";
        mac = "f6:09:d2:a3:b9:ef";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/rates-worker2"; } ];
  };
}
