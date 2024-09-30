{
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.lab

    labs
    cluster.client
    nvidia
  ];

  rnl.storage.disks.root = ["/dev/nvme0n1"];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  # To be able to use VNC we need to connect the monitor to the motherboard
  # instead of the graphics card. So we need to disable the NVIDIA drivers.
  services.xserver.videoDrivers = lib.mkForce ["modesetting" "fbdev"];

  rnl.labels.location = "inf1-p1-lab6";
}
