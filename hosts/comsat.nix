{ profiles, config, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Servidor de email";

    uefi = false;
    vcpu = 4;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "pub";
        mac = "52:54:00:f8:10:b7";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/comsat.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/lvm/comsat_home.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/lvm/comsat_spool.img";
      }
    ];
  };
}
