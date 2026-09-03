{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "adaptive_adapted_for_coderunner";
  version = "2021112300";

  pluginType = "qbehaviour";

  src = fetchzip {
    url = "https://github.com/trampgeek/moodle-qbehaviour_adaptive_adapted_for_coderunner/archive/refs/tags/v1.4.1.zip";
    sha256 = "sha256-uNbYDjkU11fNRSfRCN1l72QX4SqKN3l85GJqi/64kd4=";
  };
}
