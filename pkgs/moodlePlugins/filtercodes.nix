{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2025102700";

  pluginType = "filter";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/38432/${pluginType}_${name}_moodle44_${version}.zip";
    sha256 = "sha256-cuCB2hUbb2hWEOdZ1cpvTHBu0y6MTf24bPIc+Z5MfMM=";
  };
}
