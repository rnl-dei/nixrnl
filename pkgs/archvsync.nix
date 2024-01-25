{
  hostname,
  lib,
  makeWrapper,
  stdenv,
  system-sendmail,
  rsync,
  ...
}:
stdenv.mkDerivation rec {
  pname = "archvsync";
  version = "20180513";

  src = fetchTarball {
    url = "https://ftp-master.debian.org/ftpsync.tar.gz";
    sha256 = "sha256:0kbmabx1vh75nwxgk44np8lrdi014447kdjw8if8l9mvaszcz707";
  };

  buildInputs = [hostname system-sendmail rsync];
  nativeBuildInputs = [makeWrapper];
  installPhase = let
    config = builtins.toFile "ftpsync.conf" ''
      MAILTO="infra-robots@rnl.tecnico.ulisboa.pt"

      INFO_MAINTAINER="RNL <rnl@rnl.tecnico.ulisboa.pt>"
      INFO_COUNTRY=PT
      INFO_LOCATION="Instituto Superior Técnico, Lisboa, Portugal"
      INFO_THROUGHPUT=1Gb

      LOGDIR=/tmp
    '';
  in ''
    mkdir -p $out/etc
    cp -r bin doc $out
    cp ${config} $out/etc/.ftpsync-wrapped.conf
    wrapProgram $out/bin/ftpsync \
      --prefix PATH : "${lib.makeBinPath buildInputs}"
  '';

  meta = with lib; {
    homepage = "https://salsa.debian.org/mirror-team/archvsync/";
    description = "Script to synchronize Debian archive mirrors";
    platforms = ["x86_64-linux"];
    maintainers = ["nuno.alves"];
  };
}
