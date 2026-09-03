{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "syntaxhighlighter";
  version = "2021052101";

  pluginType = "filter";

  src = fetchzip {
    url = "https://github.com/sharpchi/moodle-filter_syntaxhighlighter/archive/refs/tags/v2021052101.zip";
    sha256 = "sha256-1bcEVFTEDygc15KcF7fB4k3hMDyrDickYGuG9T8CwX0=";
  };
}
