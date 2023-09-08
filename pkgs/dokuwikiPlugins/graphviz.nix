{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "graphviz";
  src = fetchzip {
    url = "https://github.com/splitbrain/dokuwiki-plugin-graphviz/archive/master.zip";
    hash = "sha256-xMp2ttOjt7LxP+m/aYBmAOjCSrocZPwQxP8Sxd/fZbs=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
