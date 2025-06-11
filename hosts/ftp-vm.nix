{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  rnl.labels.location = "neo";

  rnl.virtualisation.guest = {
    description = "VM for supporting ftp transition";
    createdBy = "vasco.petinga";

    memory = 8192;
    vcpu = 4;

    interfaces = [
      {
        source = "dmz";
        mac = "17:5e:54:fe:ec:52";
      }
    ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/ftp-vm"; } ];
  };

  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "193.136.164.178";
        prefixLength = 26;
      }
    ];

    defaultGateway.address = "193.136.164.190";
  };
}
