{rakeLeaves, ...}: final: prev:
prev.lib.mapAttrsRecursive
(_: path: (prev.callPackage path {}))
(rakeLeaves ../pkgs)
