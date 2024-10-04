{ stdenv, fetchzip, ... }:
stdenv.mkDerivation rec {
  name = "htmlok";
  version = "2023-05-10";

  src = fetchzip {
    url = "https://github.com/saggi-dw/dokuwiki-plugin-htmlok/archive/refs/tags/${version}.zip";
    hash = "sha256-3s+WAb1BG2mq8+wxpQ6HgPJZ+dx6v5e+vMXaOiLYceo=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
