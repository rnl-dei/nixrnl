{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "mergeusers";
  version = "2024060300";

  pluginType = "tool";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/32263/${pluginType}_${name}_moodle44_${version}.zip";
    sha256 = "sha256-yEMK7+8PFjpGA0fhangwAUrJlLJa/l6rNGOm6554M/o=";
  };
}
