{
  bash,
  coreutils,
  gnugrep,
  gnused,
  lib,
  makeWrapper,
  mariadb,
  mysqlPackage ? mariadb,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "mysql-check-state";
  version = "1.0";

  src = lib.cleanSource ./.;

  buildInputs = [
    bash
    coreutils
    gnugrep
    gnused
    mysqlPackage
  ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
       mkdir -p $out/bin
       cp mysql-check-state.sh $out/bin
       chmod +x $out/bin/mysql-check-state.sh
       wrapProgram $out/bin/mysql-check-state.sh \
    --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
    maintainers = [ "nuno.alves" ];
  };
}
