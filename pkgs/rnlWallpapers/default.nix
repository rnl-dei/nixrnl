{lib, ...}: let
  # Only import the files that end with .png/jpeg/jpg
  getSuffix = path: let
    isPng = lib.hasSuffix ".png" path;
    isJpeg = lib.hasSuffix ".jpeg" path;
    isJpg = lib.hasSuffix ".jpg" path;
  in
    if isPng
    then ".png"
    else if isJpeg
    then ".jpeg"
    else if isJpg
    then ".jpg"
    else null;

  listWallpaperFiles = path:
    lib.filterAttrs (
      name: type: (getSuffix name) != null && type == "regular"
    ) (builtins.readDir path);

  wallpapers = lib.mapAttrs' (name: _: {
    name = lib.removeSuffix (getSuffix name) name;
    value = ./wallpapers/${name};
  }) (listWallpaperFiles ./wallpapers);
in
  wallpapers
