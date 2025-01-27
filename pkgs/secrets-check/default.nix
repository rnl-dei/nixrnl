{
  bash,
  jq,
  lib,
  makeWrapper,
  stdenv,
  unixtools,
  ...
}:
stdenv.mkDerivation rec {
  name = "secrets-check";
  src = ./.;

  buildInputs = [
    bash
    jq
    unixtools.xxd
  ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
