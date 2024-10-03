{profiles, ...}: {
  imports = with profiles; [
    core.third-party
    filesystems.simple-uefi
    os.ubuntu
    type.vm
  ];

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "VM para apoio à tese do Guillermo Bettencourt"; # spellchecker:disable-line
    createdBy = "nuno.alves";
    maintainers = ["miguel.pardal" "guillermo.bettencourt"];

    uefi = false;
    memory = 4096;
    vcpu = 6;

    interfaces = [
      {
        source = "dmz";
        mac = "52:54:00:74:86:ba";
      }
    ];
    disks = [
      {
        source.dev = "/dev/zvol/dpool/data/soquest";
      }
    ];
  };

  rnl.db-cluster = {
    ensureDatabases = ["soquest_moodle"];
    ensureUsers = [
      {
        name = "soquest";
        ensurePermissions = {
          "soquest_moodle.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
