{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "coderunner";
  version = "2023091800";

  pluginType = "qtype";

  src = fetchzip {
    url = "https://github.com/trampgeek/moodle-qtype_coderunner/archive/refs/tags/v5.2.2.zip";
    sha256 = "sha256-a3aR7iyuaOty08+6e7kF/kRIhgqfpp7kc661e+z3UA0=";
  };
}
