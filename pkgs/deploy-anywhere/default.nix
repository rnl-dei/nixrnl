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
    inputs.nixos-anywhere.packages.x86_64-linux.nixos-anywhere # Used to deploy
    inputs.agenix.packages.x86_64-linux.agenix # Used to decrypt host keys
  ];
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp ${name}.sh $out/bin/${name}
    chmod +x $out/bin/${name}
    wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath buildInputs}
  '';
}
