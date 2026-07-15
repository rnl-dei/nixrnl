{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "dompdf";
  version = "2021062802";

  pluginType = "local";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/32603/${pluginType}_${name}_moodle44_${version}.zip";
    sha256 = "sha256-wLXGQZoO6cLz8PY+1PrOTeblpaUiJYnBCCDU9BRqiCM=";
  };
}
