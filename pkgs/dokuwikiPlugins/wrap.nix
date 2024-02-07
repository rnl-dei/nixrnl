{
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation {
  name = "wrap";
  src = fetchzip {
    url = "https://github.com/selfthinker/dokuwiki_plugin_wrap/archive/master.zip";
    sha256 = "sha256-XVmrIUVD0Q6F8BXByhYd0bKtvVK22LLpijVXHTrZD2k=";
  };
  installPhase = "mkdir -p $out; cp -R * $out/";
}
