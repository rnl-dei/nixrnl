{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.labs
    os.nixos
    type.physical

    labs
    gitlab-runner.es
  ];

  networking.enableIPv6 = false;

  rnl.storage.disks.root = ["/dev/nvme0n1"];
  rnl.windows-labs.partition = "/dev/nvme0n1p2";

  rnl.labels.location = "inf1-p2-lab2";
}
