{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
  ];

  rnl.storage.disks.root = ["/dev/nvme0n1"];

  rnl.labels.location = "inf1-p2-lab2";
}
