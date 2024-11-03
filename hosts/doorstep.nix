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
    description = "Servidor DHCP da rede portateis";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "portateis";
        mac = "52:54:00:6a:17:be";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/doorstep.img";
      }
    ];
  };
}
