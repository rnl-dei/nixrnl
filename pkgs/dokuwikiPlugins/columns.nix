{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation rec {
  name = "columns";
  src = fetchzip {
    url = "https://github.com/dwp-forge/columns/archive/master.zip";
    hash = "sha256-YDWNisvvwt2uuYJUsDrXZIxtoh26SmXUnNmMCPx9OJQ=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
