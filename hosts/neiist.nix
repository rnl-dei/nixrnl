{ profiles, ... }:
{
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Webserver do NEIIST";
    maintainers = [ "neiist" ];

    uefi = false;
    memory = 4096;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:ef:b5:13";
        addressBus = "0x00";
        addressSlot = "0x05";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/neiist"; } ];
  };

  rnl.db-cluster = {
    ensureDatabases = [ "neiist" ];
    ensureUsers = [
      {
        name = "neiist";
        ensurePermissions = {
          "neiist.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
