{ profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  rnl.labels.location = "zion";

  rnl.virtualisation.guest = {
    description = "Servidor de dhcp da rede de portáteis.";
    createdBy = "vasco.morais";

    memory = 4096;
    vcpu = 2;

    interfaces = [ { source = "portateis"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/doorstep"; } ];
  };

  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "10.16.81.251";
        prefixLength = 23;
      }
    ];

    defaultGateway.address = "10.16.81.254";
  };
}
