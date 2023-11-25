{
  fetchzip,
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "RAaaS";
  version = "2.0.1";

  src = fetchzip {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/pub/rnl-pkgs/${pname}/v${version}.zip";
    hash = "";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/raaas
    cp -r * $out/share/raaas

    runHook postInstall
  '';

  meta = with lib; {
    description = "RNL Artwork (generator) as a Service";
    license = licenses.mit;
    maintainers = ["nuno.alves"];
  };
}
