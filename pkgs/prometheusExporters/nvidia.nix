{
  pkgs,
  fetchzip,
  lib,
  makeWrapper,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  owner = "utkuozdemir";
  pname = "nvidia_gpu_exporter";
  version = "1.2.0";

  src = fetchzip {
    url = "https://github.com/${owner}/${pname}/releases/download/v${version}/${pname}_${version}_linux_x86_64.tar.gz";
    hash = "sha256-HkDIfo+Jry+a37dqtPSBp9SOcgxwObIYv3ss4zhT9No=";
    stripRoot = false;
  };
  buildInputs = [ pkgs.linuxKernel.packages.linux_6_1.nvidia_x11 ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp nvidia_gpu_exporter $out/bin
    wrapProgram $out/bin/nvidia_gpu_exporter \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "NVIDIA GPU exporter for prometheus using nvidia-smi binary";
    license = licenses.mit;
    maintainers = [ "martim.monis" ];
  };
}
