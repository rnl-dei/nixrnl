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
        inherit inputs profiles pkgs;
        lib = self;
      });

    pkgs = import nixpkgs {system = "x86_64-linux";};
    nixosConfigurations = lib.rnl.mkHosts ./hosts;
    profiles = lib.rnl.mkProfiles ./profiles;
  in {
    inherit nixosConfigurations;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
