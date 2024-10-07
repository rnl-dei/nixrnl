{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2023062000";

  pluginType = "mod";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29492/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-XkvckkhUb4zr9R8d4F+Feb14RialMXfWQgO5s58hpAA=";
  };
}
