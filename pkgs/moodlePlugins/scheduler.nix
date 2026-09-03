{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "scheduler";
  version = "2023052300";

  pluginType = "mod";

  src = fetchFromGitHub {
    owner = "learnweb";
    repo = "moodle-mod_scheduler";
    rev = "v4.0.0";
    sha256 = "sha256-6ztUR5LxhtJISwU4/Z0Vcbx2rirBmIPAmYVmkU9aqTo=";
  };
}
