{
  description = "NixOS @ RNL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    unstable,
    ...
  } @ inputs: let
    lib = nixpkgs.lib.extend (self: super:
      import ./lib {
        inherit inputs profiles pkgs nixosConfigurations;
        lib = self;
      });

    overlays = lib.rnl.mkOverlays ./overlays;
    pkgs = lib.rnl.mkPkgs overlays;
    nixosConfigurations = lib.rnl.mkHosts ./hosts;
    profiles = lib.rnl.mkProfiles ./profiles;
  in {
    inherit nixosConfigurations overlays;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
