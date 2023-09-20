{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "note";
  src = fetchzip {
    url = "https://github.com/lpaulsen93/dokuwiki_note/archive/master.zip";
    hash = "sha256-y2BWI0+EZak2tDyNVdxWV5YLOSqitOD8nPcAx4aCSeU=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
