{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab

    labs
    cluster.client
    cluster.tests
  ];

  rnl.storage.disks.root = [ "/dev/sda" ];

  rnl.labels.location = "inf1-p01-estaleiro";
}
