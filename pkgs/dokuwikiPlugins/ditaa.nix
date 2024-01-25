{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "ditaa";
  src = fetchzip {
    url = "https://github.com/splitbrain/dokuwiki-plugin-ditaa/archive/master.zip";
    hash = "sha256-Y1isJ2IDD++LXzBdgNmgPaTrSlqdfUy3EzlWJk4Ik9c=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
