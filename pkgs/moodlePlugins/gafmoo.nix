{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "gafmoo";
  version = "2026090100";

  pluginType = "webservice";

  src = fetchzip {
    url = "https://gitlab.rnl.tecnico.ulisboa.pt/ist13500/gafmoo/-/archive/master/gafmoo-master.zip";
    sha256 = "sha256-Fm8+Rl/VU3lQKC7eIG77DodXp5g4VEtLYcgGSYyg+JU=";
  };
}
