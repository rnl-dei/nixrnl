{profiles, ...}: {
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.windows
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Servidor share DFS do domínio WINRNL (Backup)";

    uefi = false;
    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "labs";
        mac = "52:54:00:97:56:a0";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/data/james";
      }
      {
        source.dev = "/dev/zvol/dpool/data/james_dfs";
      }
    ];
  };
}
