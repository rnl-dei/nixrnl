{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "adaptive_adapted_for_coderunner";
  version = "2021112300";

  pluginType = "qbehaviour";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/25541/${pluginType}_${name}_moodle43_${version}.zip";
    sha256 = "sha256-Fm8+Rl/VU3lQKC7eIG77DodXp5g4VEtLYcgGSYyg+JU=";
  };
}
