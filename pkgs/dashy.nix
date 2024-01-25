{
  fetchFromGitHub,
  lib,
  mkYarnPackage,
  configFile ? null,
  nodejs ? nodejs-16_x,
  nodejs-16_x,
  ...
}:
mkYarnPackage rec {
  pname = "dashy";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "Lissy93";
    repo = pname;
    rev = version;
    sha256 = "sha256-8+J0maC8M2m+raiIlAl0Bo4HOvuuapiBhoSb0fM8f9M=";
  };

  inherit nodejs;
  NODE_OPTIONS = "--openssl-legacy-provider";

  preConfigure = lib.optionalString (configFile != null) ''
    rm public/conf.yml
    cp ${configFile} public/conf.yml
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    # https://stackoverflow.com/questions/49709252/no-postcss-config-found
    echo 'module.exports = {};' > postcss.config.js
    yarn build --offline --mode production

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/dashy
    mv ./deps/Dashy/dist/* $out/share/dashy/

    runHook postInstall
  '';

  dontFixup = true;
  doDist = false;

  meta = with lib; {
    description = "A self-hostable personal dashboard built for you. Includes status-checking, widgets, themes, icon packs, a UI editor and tons more!";
    homepage = "https://dashy.to/";
    license = licenses.mit;
    maintainers = ["nuno.alves"];
  };
}
