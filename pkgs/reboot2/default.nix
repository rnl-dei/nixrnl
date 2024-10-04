{
  bash,
  grub2,
  lib,
  makeWrapper,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "reboot2";
  version = "1.0";

  src = lib.cleanSource ./src;
  buildInputs = [
    bash
    grub2
  ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    for i in *; do
      i=''${i%.sh}
      cp $i.sh $out/bin/$i
      chmod +x $out/bin/$i
      wrapProgram $out/bin/$i \
        --prefix PATH : ${lib.makeBinPath buildInputs}
    done
  '';

  meta = with lib; {
    platforms = [ "x86_64-linux" ];
    maintainers = [ "nuno.alves" ];
  };
}
