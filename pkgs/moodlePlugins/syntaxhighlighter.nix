{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "syntaxhighlighter";
  version = "2021052101";

  pluginType = "filter";

  src = fetchFromGitHub {
    owner = "sharpchi";
    repo = "moodle-filter_syntaxhighlighter";
    rev = "v2021052101";
    sha256 = "sha256-1bcEVFTEDygc15KcF7fB4k3hMDyrDickYGuG9T8CwX0=";
  };
}
