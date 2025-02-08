{
  bash,
  inputs,
  lib,
  makeWrapper,
  stdenv,
  vault-bin,
}:
stdenv.mkDerivation rec {
  name = "deploy-anywhere";
  src = ./.;

  buildInputs = [
    bash
    vault-bin
    inputs.nixos-anywhere.packages.${stdenv.system}.nixos-anywhere # Used to deploy
    inputs.agenix.packages.${stdenv.system}.agenix # Used to decrypt host keys
  ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
