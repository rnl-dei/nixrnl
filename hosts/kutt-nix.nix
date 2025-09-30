{
  profiles,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    containers.docker
    # future kutt profile here
  ];

  rnl.labels.location = "atlas";

  rnl.virtualisation.guest = {
    description = "URL shortener da RNL - nix version";
    createdBy = "vasco.petinga";

    memory = 6144;
    vcpu = 2;

    interfaces = [
      {
        source = "dmz";
        mac = "9e:cf:07:d1:8e:2d";
      }
    ];
    disks = [
      { source.dev = "/dev/zvol/dpool/volumes/kutt"; }
      { source.dev = "/dev/zvol/dpool/data/kutt"; } # for docker volumes / databases to backup
    ];
  };

  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = "193.136.164.179";
        prefixLength = 26;
      }
    ];

    interfaces.enp1s0.ipv6.addresses = [
      {
        address = "2001:690:2100:83::179";
        prefixLength = 64;
      }
    ];

    defaultGateway.address = "193.136.164.190";
  };
}
