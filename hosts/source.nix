{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Builder de Gentoo";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "priv";
        mac = "52:54:00:8f:52:11";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/source.img";
      }
    ];
  };
}
