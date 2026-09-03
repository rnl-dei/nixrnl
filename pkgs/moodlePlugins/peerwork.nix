{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2025032200";

  pluginType = "mod";

  src = fetchzip {
    url = "https://github.com/amandadoughty/moodle-mod_peerwork/archive/refs/tags/4.5.0.5.zip";
    sha256 = "sha256-XQaIDFMnU0HBlIBCj4UXKeoycouhhVssqa71DiTu84o=";
  };

}
