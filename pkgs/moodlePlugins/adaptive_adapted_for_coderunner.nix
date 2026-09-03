{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "adaptive_adapted_for_coderunner";
  version = "2021112300";

  pluginType = "qbehaviour";

  src = fetchFromGitHub {
    owner = "trampgeek";
    repo = "moodle-qbehaviour_adaptive_adapted_for_coderunner";
    rev = "v1.4.1";
    sha256 = "sha256-uNbYDjkU11fNRSfRCN1l72QX4SqKN3l85GJqi/64kd4=";
  };
}
