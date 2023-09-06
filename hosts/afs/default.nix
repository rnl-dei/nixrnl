{profiles, ...}: {
  imports = with profiles; [
    core.dsi
    filesystems.unknown
    os.debian
    type.generic
  ];

  rnl.labels.location = "dsi";
}
