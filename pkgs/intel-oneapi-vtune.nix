{
  autoPatchelfHook,
  dpkg,
  alsa-lib,
  at-spi2-atk,
  cups,
  electron,
  expat,
  fetchurl,
  ffmpeg,
  gtk3,
  kmod,
  lib,
  libdrm,
  libndctl,
  udev,
  libuuid,
  libxcrypt-legacy,
  libxkbcommon,
  makeDesktopItem,
  mesa,
  ncurses5,
  nspr,
  nss,
  pango,
  systemd,
  stdenv,
  wrapGAppsHook,
  xorg,
  zlib,
  ...
}:
stdenv.mkDerivation rec {
  pname = "intel-oneapi-vtune";
  version = "2023.1.0";

  src = fetchurl {
    url = "https://apt.repos.intel.com/oneapi/pool/main/${pname}-${version}-44286_amd64.deb";
    sha256 = "sha256-dw2VA9B0EdlKRcjgzzIOGzjSLhLsPDmnacwTgAjyFEo=";
  };

  unpackPhase = "dpkg-deb -x $src .";

  nativeBuildInputs = [autoPatchelfHook dpkg wrapGAppsHook];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-atk
    cups
    electron
    expat
    gtk3
    kmod
    libdrm
    libndctl
    libuuid
    libxcrypt-legacy
    libxkbcommon
    mesa
    ncurses5
    nspr
    nss
    pango
    systemd
    udev
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXrandr
    zlib
  ];

  runtimeDependencies = [
    ffmpeg
    udev # Will crash on launch without udev.
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libffi.so.6"
    "libgdbm.so.4"
    "libgdbm_compat.so.4"
    "libsafec-3.3.so.3"
    "libsycl.so.6"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r opt $out
    ln -s $out/opt/intel/oneapi/vtune/${version}/bin64/* $out/bin/
    rm $out/bin/pin $out/bin/pinbin

    # icon
    mkdir -p "$out/share/icons/hicolor/128x128/apps"
    ln -s "$out/opt/intel/oneapi/vtune/${version}/bin64/resources/app/icons/VTune.png" "$out/share/icons/hicolor/128x128/apps/vtune.png"

    # desktop item
    mkdir -p "$out/share/applications"
    ln -s "${desktopItem}/share/applications/vtune-gui.desktop" "$out/share/applications"
  '';

  desktopItem = makeDesktopItem {
    name = "vtune-gui";
    desktopName = "Intel VTune Profiler";
    comment = meta.description;
    genericName = "VTune";
    exec = "vtune-gui";
    icon = "vtune";
    startupNotify = false;
    categories = ["Development"];
    mimeTypes = ["text/plain"];
    keywords = ["vtune"];
  };

  meta = with lib; {
    homepage = "https://software.intel.com/content/www/us/en/develop/tools/oneapi.html";
    description = "Intel® VTune(TM) Profiler";
    platforms = ["x86_64-linux"];
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    maintainers = ["carlos.vaz"];
  };
}
