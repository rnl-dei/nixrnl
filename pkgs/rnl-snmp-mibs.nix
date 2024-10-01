{
  fetchzip,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  name = "rnl-snmp-mibs";

  # TODO: Get MIBS from the original source or from a external repository
  src = fetchzip {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/tmp/mibs.zip";
    hash = "sha256-BiRX31lfvOLT5UkvD4P1f3CFgoiQ1gS1ZCEXzE9Q++Q=";
  };

  installPhase = ''
    mkdir -p $out/share/snmp/mibs
    find $src -name '*.txt' -exec cp -r {} $out/share/snmp/mibs \;
  '';
}
