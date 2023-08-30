{
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
    nvidia
  ];

  rnl.storage.disks.root = ["/dev/sda"];

  # To be able to use VNC we need to connect the monitor to the motherboard
  # instead of the graphics card. So we need to disable the NVIDIA drivers.
  services.xserver.videoDrivers = lib.mkForce ["modesetting" "fbdev"];

  rnl.labels.location = "inf1-p1-lab6";
}
