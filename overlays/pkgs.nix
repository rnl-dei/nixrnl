self: super: rec {
  rnl =
    super.lib.mapAttrs'
    (name: value:
      super.lib.nameValuePair
      (super.lib.removeSuffix ".nix" name)
      (super.callPackage ../pkgs/${name} {}))
    (builtins.readDir ../pkgs);
}
