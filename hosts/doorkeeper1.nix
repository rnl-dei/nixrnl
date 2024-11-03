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
    description = "Servidor DHCP e VPN da rede GIA";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "gia";
        mac = "52:54:00:cc:84:26";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/doorkeeper1_root.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/doorkeeper1_shared.img";
      }
    ];
  };
}
