{
  rakeLeaves,
  inputs,
  ...
}: _final: prev:
prev.lib.mapAttrsRecursive
(_: path: (prev.callPackage path {inherit inputs;}))
(rakeLeaves ../pkgs)
