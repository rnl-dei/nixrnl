{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.zfs-raid6
    os.nixos
    type.vm
  ];

  rnl.labels.location = "atlas";

  rnl.virtualisation.guest = {
    description = "VM for supporting ftp transition";
    createdBy = "vasco.petinga";

    uefi = false;

    directKernel = {
      kernel = config.rnl.virtualisation.kernels.shell;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };
    interfaces = [
      {
        source = "dmz";
        mac = "17:5e:54:fe:ec:52";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/lvm/ftp.img";
      }
    ];
  };
}