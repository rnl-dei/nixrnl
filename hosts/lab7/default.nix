{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
  ];

  rnl.storage.disks.root = ["/dev/sda"];

  rnl.labels.location = "inf1-p1-lab7";
}
