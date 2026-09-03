{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "scheduler";
  version = "2023052300";

  pluginType = "mod";

  src = fetchzip {
    url = "https://github.com/learnweb/moodle-mod_scheduler/archive/refs/tags/v4.0.0.zip";
    sha256 = "sha256-6ztUR5LxhtJISwU4/Z0Vcbx2rirBmIPAmYVmkU9aqTo=";
  };
}
