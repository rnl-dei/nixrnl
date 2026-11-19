{ inputs, ... }:
# HACK: Pull patched Nginx from PR #589961 until the fix lands in our nixpkgs branch.
# Remove once nixpkgs includes the update/backport.
_final: prev:
let
  patched = inputs.nixpkgs-nginx-fix.legacyPackages.${prev.system};
in
{
  inherit (patched)
    nginx
    nginxStable
    nginxMainline
    ;
}
