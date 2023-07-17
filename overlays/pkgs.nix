final: prev: rec {
  rnl =
    prev.lib.mapAttrs'
    (name: value:
      prev.lib.nameValuePair
      (prev.lib.removeSuffix ".nix" name)
      (prev.callPackage ../pkgs/${name} {}))
    (builtins.readDir ../pkgs);
}
