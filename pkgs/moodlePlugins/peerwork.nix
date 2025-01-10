{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2024122401";

  pluginType = "mod";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/34326/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-asokTbWf+wKYLmeVzensuKLdBwTKgIFJdwKKTb8UlCs=";
  };

}
