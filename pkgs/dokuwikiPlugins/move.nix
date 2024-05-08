{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "move";

  src = fetchzip {
    url = "https://github.com/michitux/dokuwiki-plugin-move/archive/master.zip";
    sha256 = "sha256-h9WHafIV5Gt1feJl9UGLxOPuahHIOzQrJSQWIdQaBNw=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
