{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "dompdf";
  version = "2021062802";

  pluginType = "local";

  src = fetchFromGitHub {
    owner = "kiklop74";
    repo = "moodle-local_dompdf";
    rev = "v1.1";
    sha256 = "sha256-6/nr6HU/Arzk/MIbTabwm5f+VJ4IJ3Qi8VZOJ6dpGsM=";
  };
}
