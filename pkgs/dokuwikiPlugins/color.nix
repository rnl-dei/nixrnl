{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "color";
  src = fetchzip {
    url = "https://github.com/hanche/dokuwiki_color_plugin/archive/master.zip";
    hash = "sha256-B9HX6uj9Y2i2QAH8Tznynhl1m0JSEEPAtYycmaUcRkQ=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
