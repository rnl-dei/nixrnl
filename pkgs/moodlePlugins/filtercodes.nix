{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2025102700";

  pluginType = "filter";

  src = fetchFromGitHub {
    owner = "michael-milette";
    repo = "moodle-filter_filtercodes";
    rev = "v2.6.1";
    sha256 = "sha256-QpaKsdNbotnDp/aWkwI/swKKOM03pF7NzZIe9Ie/YOY=";
  };
}
