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
    description = "Worker do sistema RATES";
    createdBy = "francisco.martins";
    maintainers = [ "luis.macorano" ];

    memory = 2048;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "ba:c2:02:b2:54:eb";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/rates-worker"; } ];
  };
}
