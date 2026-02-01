{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab
    labs
    exam
    cluster.client
  ];

  # Disable IPv6 since there is a bug on the network card
  # that causes IPv6 to stop working when the computer reboots from
  # Windows to Linux.
  networking.enableIPv6 = false;

  rnl.storage.disks.root = [ "/dev/nvme0n1" ];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab2";

  rnl.monitoring.amt = true;
}
