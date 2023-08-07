{
  rakeLeaves,
  inputs,
  ...
}: final: prev:
prev.lib.mapAttrsRecursive
(_: path: (prev.callPackage path {inherit inputs;}))
(rakeLeaves ../pkgs)
