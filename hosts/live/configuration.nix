{inputs, ...}: {
  aliases = {
    live = { extraModules = [(inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")]; };
    live-netboot = { extraModules = [(inputs.nixpkgs + "/nixos/modules/installer/netboot/netboot-minimal.nix")]; };
  };
}
