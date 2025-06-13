{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab
    exam
    labs
    cluster.client
    nvidia
  ];

  rnl.storage.disks.root = [ "/dev/nvme0n1" ];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab3";

  rnl.monitoring.amt = true;
}
