{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2025032200";

  pluginType = "mod";

  src = fetchFromGitHub {
    owner = "amandadoughty";
    repo = "moodle-mod_peerwork";
    rev = "4.5.0.5";
    sha256 = "sha256-XQaIDFMnU0HBlIBCj4UXKeoycouhhVssqa71DiTu84o=";
  };

}
