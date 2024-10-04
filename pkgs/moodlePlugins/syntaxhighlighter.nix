{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "syntaxhighlighter";
  version = "2021052101";

  pluginType = "filter";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/24270/${pluginType}_${name}_moodle41_${version}.zip";
    sha256 = "sha256-1bcEVFTEDygc15KcF7fB4k3hMDyrDickYGuG9T8CwX0=";
  };
}
