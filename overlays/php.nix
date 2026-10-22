{ inputs, ... }:
# HACK: nixos-25.05 is EOL and will not get the fixes for CVE-2026-109618/CVE-2026-109619 (php2shell),
# so take PHP from nixos-26.05 (8.2.35, 8.3.36, 8.4.27). Remove once nixpkgs is bumped to 26.05.
_final: prev:
let
  patched = inputs.nixpkgs-php.legacyPackages.${prev.system};
in
{
  inherit (patched)
    php
    php82
    php83
    php84
    ;
}
