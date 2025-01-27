{
  bash,
  coreutils,
  findutils,
  gnused,
  lib,
  makeWrapper,
  stdenv,
  system-sendmail,
  ...
}:
stdenv.mkDerivation rec {
  pname = "wsrep-notify";
  version = "1.0";

  src = lib.cleanSource ./.;
  buildInputs = [
    bash
    coreutils
    findutils
    gnused
    system-sendmail
  ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp wsrep-notify-script.sh $out/bin
    chmod +x $out/bin/wsrep-notify-script.sh
    wrapProgram $out/bin/wsrep-notify-script.sh \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = {
    platforms = [ "x86_64-linux" ];
    maintainers = [ "nuno.alves" ];
  };
}
