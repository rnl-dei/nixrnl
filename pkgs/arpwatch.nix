{
  fetchurl,
  lib,
  libpcap,
  system-sendmail,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "arpwatch";
  version = "3.8";

  src = fetchurl {
    url = "https://ee.lbl.gov/downloads/${pname}/${pname}-${version}.tar.gz";
    sha256 = "sha256-x2NAnzU0uLPxGRc82SpLnUI3i2xmbMALJVzANtMYspw=";
  };

  patchPhase = ''
    sed -i '1i#include <time.h>' report.c
    sed -i 's/\<_getshort\>/ns_get16/g' dns.c
    # This package currently is using a deprecated function. Solution found here: https://s.rnl.pt/UvUQ9X
  '';

  preInstall = ''
    install -d -m 0755 $out/bin
    install -d -m 0755 $out/etc/rc.d
    install -d -m 0755 $out/share/man/man8
  '';

  configureFlags = [ "--sbindir=${placeholder "out"}/bin" ];

  buildInputs = [
    libpcap
    system-sendmail
  ];

  meta = with lib; {
    homepage = "https://ee.lbl.gov/";
    platforms = platforms.linux;
    license = licenses.bsd3;
  };
}
