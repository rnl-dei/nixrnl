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
    createdBy = ["francisco.martins" "vasco.morais"];

    memory = 4096;
    vcpu = 2;

    interfaces = [ { source = "portateis"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/data/doorstep"; } ];
  };
}