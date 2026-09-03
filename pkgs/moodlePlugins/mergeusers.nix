{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "mergeusers";
  version = "2024060300";

  pluginType = "tool";

  src = fetchzip {
    url = "https://github.com/jpahullo/moodle-tool_mergeusers/archive/refs/tags/2024060300.zip";
    sha256 = "sha256-Cwfpz0IFW+NCoIkQ/aDVyI8ET44N2gu1SHXRUv/vFnY=";
  };
}
