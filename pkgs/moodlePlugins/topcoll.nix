{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "topcoll";
  version = "2022041900";

  pluginType = "format";

  src = fetchFromGitHub {
    owner = "gjbarnard";
    repo = "moodle-format_topcoll";
    rev = "V400.1.3";
    sha256 = "sha256-r9hdHlqVQmnHHkwqvIKiEMJ1SYuzlHn64f46GXHXjdc=";
  };
}
