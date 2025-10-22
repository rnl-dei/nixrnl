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
    # gitlab-runner.es
  ];

  rnl.storage.disks.root = [ "/dev/nvme0n1" ];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p1-lab6";

  rnl.monitoring.amt = true;
}
