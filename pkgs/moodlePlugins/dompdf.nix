{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "dompdf";
  version = "2021062802";

  pluginType = "local";

  src = fetchzip {
    url = "https://github.com/kiklop74/moodle-local_dompdf/archive/refs/tags/v1.1.zip";
    sha256 = "sha256-6/nr6HU/Arzk/MIbTabwm5f+VJ4IJ3Qi8VZOJ6dpGsM=";
  };
}
