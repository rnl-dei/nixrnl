{ inputs, ... }:
# HACK: nixos-25.05 is EOL; pull patched Nginx and compatible nginxModules from PR #589961
# until nixpkgs is bumped.
_final: prev:
let
  patched = inputs.nixpkgs-nginx-fix.legacyPackages.${prev.system};
in
{
  inherit (patched)
    nginx
    nginxStable
    nginxMainline
    nginxModules
    ;
}
