{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2025102700";

  pluginType = "filter";

  src = fetchzip {
    url = "https://github.com/michael-milette/moodle-filter_filtercodes/archive/refs/tags/v2.6.1.zip";
    sha256 = "sha256-QpaKsdNbotnDp/aWkwI/swKKOM03pF7NzZIe9Ie/YOY=";
  };
}
