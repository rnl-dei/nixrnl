{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "scheduler";
  version = "2024122401";

  pluginType = "mod";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29293/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-6ztUR5LxhtJISwU4/Z0Vcbx2rirBmIPAmYVmkU9aqTo=";
  };
}
