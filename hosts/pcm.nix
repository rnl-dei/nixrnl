{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Teses e cadeira de PCM (Moodle)";
    maintainers = ["daniel.goncalves"];

    uefi = false;
    memory = 2048;
    vcpu = 8;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:a4:be:aa";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [{source.dev = "/dev/zvol/dpool/volumes/pcm";}];
  };
}
