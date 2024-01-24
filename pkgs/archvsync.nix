{
  stdenv,
  lib,
  makeWrapper,
  ...
}:
stdenv.mkDerivation rec {
  pname = "archvsync";
  version = "20180513";

  src = fetchTarball {
    url = "https://ftp-master.debian.org/ftpsync.tar.gz";
    sha256 = "sha256:0kbmabx1vh75nwxgk44np8lrdi014447kdjw8if8l9mvaszcz707";
  };

  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out
    cp -r bin doc $out
  '';

  meta = with lib; {
    homepage = "https://salsa.debian.org/mirror-team/archvsync/";
    description = "Script to synchronize Debian archive mirrors";
    platforms = ["x86_64-linux"];
    maintainers = ["nuno.alves"];
  };
}
