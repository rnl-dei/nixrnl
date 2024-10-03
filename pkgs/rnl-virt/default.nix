{
  lib,
  libvirt,
  makeWrapper,
  python3,
  qemu,
  stdenv,
  virt-manager,
  virt-viewer,
  ...
}:
stdenv.mkDerivation rec {
  pname = "rnl-virt";
  version = "1.0";

  src = lib.cleanSource ./.;
  buildInputs = [libvirt python3 qemu virt-manager virt-viewer];
  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    cp rnl-virt $out/bin
    wrapProgram $out/bin/rnl-virt \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    platforms = ["x86_64-linux"];
    maintainers = ["carlos.vaz"];
  };
}
