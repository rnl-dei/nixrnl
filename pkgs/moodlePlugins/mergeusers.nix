{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "mergeusers";
  version = "2024060300";

  pluginType = "tool";

  src = fetchFromGitHub {
    owner = "jpahullo";
    repo = "moodle-tool_mergeusers";
    rev = "2024060300";
    sha256 = "sha256-Cwfpz0IFW+NCoIkQ/aDVyI8ET44N2gu1SHXRUv/vFnY=";
  };
}
