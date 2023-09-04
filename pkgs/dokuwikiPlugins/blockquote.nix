{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "blockquote";
  src = fetchzip {
    url = "https://github.com/dokufreaks/plugin-blockquote/archive/master.zip";
    hash = "sha256-V5owCHYyf2JDtE5nxuyYDnLHmFx5pxQADbbuE9p4Qss=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
