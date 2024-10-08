{ inputs, lib, ... }:
{
  aliases = {
    live = {
      extraModules = [ (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix") ];
    };
    live-dhcp = {
      extraModules = [
        (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
        { networking.useDHCP = lib.mkForce true; }
      ];
    };
    live-netboot-dhcp = {
      extraModules = [
        (inputs.nixpkgs + "/nixos/modules/installer/netboot/netboot-minimal.nix")
        {
          networking.useDHCP = lib.mkForce true;
          networking.dhcpcd.extraConfig = ''
            duid ll   # Allow DHCP server to assign a static IPv6 using the MAC address
          '';
        }
      ];
    };
  };
}
