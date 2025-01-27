{ config, profiles, ... }:
{
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.gentoo
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Jobe server para plugin CodeRunner no Moodle do DEI";
    createdBy = "rnl";
    maintainers = [ "dei" ];

    memory = 4096;
    uefi = false;
    directKernel = {
      kernel = config.rnl.virtualisation.kernels.minimal;
      cmdline = "root=/dev/vda console=hvc0 clocksource=kvm-clock";
    };

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:5b:e2:e4";
      }
    ];
    disks = [
      {
        type = "file";
        source.file = "/mnt/data/coderunner.img";
      }
    ];
  };
}
