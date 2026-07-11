{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2025032200";

  pluginType = "mod";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/35393/${pluginType}_${name}_moodle45_${version}.zip";
    sha256 = "sha256-XQaIDFMnU0HBlIBCj4UXKeoycouhhVssqa71DiTu84o=";
  };

}
