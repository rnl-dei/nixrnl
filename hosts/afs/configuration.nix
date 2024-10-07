{ lib, ... }:
{
  aliases = builtins.listToAttrs (
    builtins.map (n: {
      name = "afs${lib.fixedWidthNumber 2 n}";
      value = { };
    }) (lib.range 1 26)
  );
}
