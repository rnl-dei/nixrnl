{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "dredd";

  rnl.virtualisation.guest = {
    description = "URL shortener da RNL";
    createdBy = "nuno.alves";

    uefi = false;

    directKernel = {
      kernel = config.rnl.virtualisation.kernels.shell;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };
    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:72:fd:58";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/kutt.img";
      }
    ];
  };
}
