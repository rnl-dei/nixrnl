{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "move";
  src = fetchzip {
    url = "https://github.com/michitux/dokuwiki-plugin-move/archive/master.zip";
    sha256 = "sha256-zgwCQbLHQAXEtDCYTBBFPEEztrGvDkJvsqieKBaUAgk=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
