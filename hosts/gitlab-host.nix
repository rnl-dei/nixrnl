{ config, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "atlas";

  rnl.virtualisation.guest = {
    description = "Gitlab Host";
    createdBy = "francisco.martins";

    uefi = false;

    directKernel = {
      kernel = config.rnl.virtualisation.kernels.shell;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };
    interfaces = [
      {
        source = "pub";
        mac = "52:54:00:1f:9f:65";
      }
      {
        source = "priv";
        mac = "52:54:00:76:70:53";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/gitlab-host.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/gitlab-data.img";
      }
    ];
  };
}
