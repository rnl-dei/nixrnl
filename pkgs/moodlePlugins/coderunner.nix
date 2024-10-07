{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "coderunner";
  version = "2023090800";

  pluginType = "qtype";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29972/${pluginType}_${name}_moodle43_${version}.zip";
    sha256 = "sha256-a3aR7iyuaOty08+6e7kF/kRIhgqfpp7kc661e+z3UA0=";
  };
}
