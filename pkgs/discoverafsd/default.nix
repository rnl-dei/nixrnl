{
  bash,
  bc,
  curl,
  lib,
  makeWrapper,
  stdenv,
  systemd,
  toybox,
  ...
}:
stdenv.mkDerivation rec {
  pname = "discoverafsd";
  version = "1.0";

  src = lib.cleanSource ./.;

  buildInputs = [
    bash
    bc
    curl
    systemd
    toybox
  ];

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
       mkdir -p $out/bin
       cp discoverafsd.sh $out/bin
       chmod +x $out/bin/discoverafsd.sh
       wrapProgram $out/bin/discoverafsd.sh \
    --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    platforms = ["x86_64-linux"];
    maintainers = ["nuno.alves"];
  };
}
