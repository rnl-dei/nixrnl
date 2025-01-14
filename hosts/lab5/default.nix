{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab

    labs
    cluster.client
    exam
  ];

  rnl.storage.disks.root = [ "/dev/nvme0n1" ];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  boot.kernelParams = [ "pcie_aspm=off" ];

  rnl.labels.location = "inf1-p2-lab5";

  rnl.monitoring.amt = true;
}
