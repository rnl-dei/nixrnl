{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "wrap";
  src = fetchzip {
    url = "https://github.com/selfthinker/dokuwiki_plugin_wrap/archive/master.zip";
    sha256 = "sha256-qIgyK6xNpo9Dr2tpgtInSjPBlkGr7EHzqrqhwHLtwNM=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
