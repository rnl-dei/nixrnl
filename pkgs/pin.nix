{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "pin";
  version = "4.2";
  urlVersion = "${version}-99776-g21d818fa2";

  src = fetchurl {
    url = "http://software.intel.com/sites/landingpage/pintool/downloads/${pname}-external-${urlVersion}-gcc-linux.tar.gz";
    sha256 = "sha256-GUos7FFnggNFLs4Nnoy7GBnrbhIh8DQQkcSSSPOE2Gk=";
  };

  buildInputs = [ stdenv.cc.cc.lib ];

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    sed -i 's/\/usr\/bin\/ar/\/usr\/bin\/env ar/' source/tools/Config/unix.vars
    cp -r ./* $out
    ln -s $out/pin $out/intel64/bin/* $out/bin
  '';

  meta = with lib; {
    homepage = "https://software.intel.com/content/www/us/en/develop/articles/pin-a-dynamic-binary-instrumentation-tool.html";
    description = "A tool for the dynamic instrumentation of programs";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [ "carlos.vaz" ];
  };
}
