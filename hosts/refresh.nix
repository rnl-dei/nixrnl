{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "VAMT do domínio WINRNL";

    memory = 8192;
    vcpu = 8;

    interfaces = [{source = "labs";}];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/refresh";}];
  };
}
