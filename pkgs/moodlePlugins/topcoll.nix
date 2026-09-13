{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "topcoll";
  version = "2021051700";

  pluginType = "format";

  src = fetchFromGitHub {
    owner = "gjbarnard";
    repo = "moodle-format_topcoll";
    rev = "V3.11.1.0";
    sha256 = "sha256-1bcEVFTEDygc15KcF7fB4k3hMDyrDickYGuG9T8CwX0=";
  };
}
