# sourced from user on nixos discord
# https://github.com/TheAyes/.ayes/blob/main/modules/nixos/utils.nix
{ lib, ... }:
let
  generateUUID =
    seed:
    let
      # Convert hex string to integer
      hexToInt =
        hexStr:
        let
          hexDigitToInt =
            d:
            if d == "0" then
              0
            else if d == "1" then
              1
            else if d == "2" then
              2
            else if d == "3" then
              3
            else if d == "4" then
              4
            else if d == "5" then
              5
            else if d == "6" then
              6
            else if d == "7" then
              7
            else if d == "8" then
              8
            else if d == "9" then
              9
            else if d == "a" || d == "A" then
              10
            else if d == "b" || d == "B" then
              11
            else if d == "c" || d == "C" then
              12
            else if d == "d" || d == "D" then
              13
            else if d == "e" || d == "E" then
              14
            else if d == "f" || d == "F" then
              15
            else
              throw "Invalid hex digit: ${d}";
          digits = lib.stringToCharacters hexStr;
          folder = acc: digit: acc * 16 + hexDigitToInt digit;
        in
        lib.foldl folder 0 digits;

      # Convert string seed to integer by hashing
      seedInt =
        if builtins.isString seed then
          hexToInt (builtins.substring 0 8 (builtins.hashString "sha256" seed))
        else
          seed;

      toHexString =
        int:
        let
          hexDigits = {
            "10" = "A";
            "11" = "B";
            "12" = "C";
            "13" = "D";
            "14" = "E";
            "15" = "F";
          };
          toHexDigit = d: if d < 10 then toString d else hexDigits.${toString d};
          shiftRight = d: shiftBy: if shiftBy <= 0 then d else shiftRight (d / 2) (shiftBy - 1);
          getFourBitSplit = d: [
            (builtins.bitAnd (shiftRight d 28) 15)
            (builtins.bitAnd (shiftRight d 24) 15)
            (builtins.bitAnd (shiftRight d 20) 15)
            (builtins.bitAnd (shiftRight d 16) 15)
            (builtins.bitAnd (shiftRight d 12) 15)
            (builtins.bitAnd (shiftRight d 8) 15)
            (builtins.bitAnd (shiftRight d 4) 15)
            (builtins.bitAnd (shiftRight d 0) 15)
          ];
        in
        lib.concatMapStrings toHexDigit (getFourBitSplit int);

      int1 = seedInt;
      int2 = builtins.bitOr (builtins.bitAnd seedInt (-61441)) 16384;
      int3 = builtins.bitOr (builtins.bitAnd seedInt 1073741823) (-2147483648);
      int4 = seedInt;
      part1 = toHexString int1;
      part2 = builtins.substring 0 4 (toHexString int2);
      part3 = builtins.substring 4 4 (toHexString int2);
      part4 = builtins.substring 0 4 (toHexString int3);
      part5 = (builtins.substring 4 4 (toHexString int3)) + (toHexString int4);
    in
    "${part1}-${part2}-${part3}-${part4}-${part5}";
in
{
  inherit generateUUID;
}
