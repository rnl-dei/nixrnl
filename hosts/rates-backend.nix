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
    description = "Backend do sistema RATES";
    createdBy = "francisco.martins";
    maintainers = [ "luis.macorano" ];

    memory = 2048;
    vcpu = 1;

    interfaces = [
      {
        source = "pub";
        mac = "f2:52:5c:f2:21:75";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/rates-backend"; } ];
  };
}
