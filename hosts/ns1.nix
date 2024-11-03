{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Nameserver primário";

    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "pub";
        mac = "52:54:00:32:0e:29";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/ns1.img";
      }
    ];
  };
}
