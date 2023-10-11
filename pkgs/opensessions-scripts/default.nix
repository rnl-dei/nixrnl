{
  lib,
  stdenv,
  bash,
  logger,
  system-sendmail,
  curl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "opensessions-script";
  version = "1.0";

  src = lib.cleanSource ./.;

  buildInputs = [
    bash
    logger
    system-sendmail
    curl    
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp session-control.sh $out/bin
    chmod +x $out/bin/session-control.sh
  '';

  meta = with lib; {
    platforms = ["x86_64-linux"];
    maintainers = ["andre.romao"];
  };
}
