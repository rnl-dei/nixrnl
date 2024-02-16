{
  autoPatchelfHook,
  bash,
  git,
  lib,
  logger,
  makeWrapper,
  stdenv,
  system-sendmail,
  ...
}:
stdenv.mkDerivation rec {
  pname = "pull-repo";
  version = "1.0";

  src = lib.cleanSource ./.;
  buildInputs = [bash git system-sendmail logger];
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    cp pull-repo $out/bin
    wrapProgram $out/bin/pull-repo \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    platforms = ["x86_64-linux"];
    maintainers = ["nuno.alves"];
  };
}
