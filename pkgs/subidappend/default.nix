{ lib, stdenv, ... }:
stdenv.mkDerivation rec {
  pname = "subidappend";
  version = "1.0";

  src = lib.cleanSource ./.;

  buildInputs = [ ];

  buildPhase = ''
    gcc subidappend.c -o subidappend
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp subidappend $out/bin
  '';

  meta = with lib; {
    maintainers = [ "carlos.vaz" ];
  };
}
