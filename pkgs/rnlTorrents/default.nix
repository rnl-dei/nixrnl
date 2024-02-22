{
  copyPathToStore,
  lib,
  ...
}: let
  # Only import the files that end with .torrent
  listTorrentFiles = path:
    lib.filterAttrs (
      name: type:
        lib.hasSuffix ".torrent" name && type == "regular"
    ) (builtins.readDir path);

  torrents = lib.mapAttrs' (name: _: {
    name = lib.removeSuffix ".torrent" name;
    value = lib.fileset.toSource {
      root = ./torrents;
      fileset = ./torrents + "/${name}";
    };
  }) (listTorrentFiles ./torrents);
in
  torrents
