{
  profiles,
  inputs,
  ...
}: {
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
    profiles.core.rnl
  ];
}
