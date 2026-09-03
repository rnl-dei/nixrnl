{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "coderunner";
  version = "2023091800";

  pluginType = "qtype";

  src = fetchFromGitHub {
    owner = "trampgeek";
    repo = "moodle-qtype_coderunner";
    rev = "v5.2.2";
    sha256 = "sha256-a3aR7iyuaOty08+6e7kF/kRIhgqfpp7kc661e+z3UA0=";
  };
}
