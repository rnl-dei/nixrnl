{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "edittable";
  src = fetchzip {
    url = "https://github.com/cosmocode/edittable/archive/master.zip";
    sha256 = "sha256-Mns8zgucpJrg1xdEopAhd4q1KH7j83Mz3wxuu4Thgsg=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
