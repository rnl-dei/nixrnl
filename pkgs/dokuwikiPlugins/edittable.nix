{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "edittable";
  src = fetchzip {
    url = "https://github.com/cosmocode/edittable/archive/master.zip";
    sha256 = "sha256-1TM7QkyNbDMQ/GR2PMKWPNHG3jhxdLNaqDbErltSsAs=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
