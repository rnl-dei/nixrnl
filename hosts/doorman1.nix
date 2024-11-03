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
    description = "Servidor de DHCP da rede Labs";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "labs";
        mac = "52:54:00:6e:69:6c";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/doorman1_root.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/doorman1_shared.img";
      }
    ];
  };
}
