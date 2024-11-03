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
    description = "Nameserver secundário";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "pub";
        mac = "52:54:00:22:83:e3";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/ns2.img";
      }
    ];
  };
}
