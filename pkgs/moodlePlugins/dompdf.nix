{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "dompdf";
  version = "2021062802";

  pluginType = "local";

  src = fetchFromGitHub {
    owner = "kiklop74";
    repo = "moodle-local_dompdf";
    rev = "v1.5";
    sha256 = "sha256-AAA";
  };
}
