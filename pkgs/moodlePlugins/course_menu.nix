{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "course_menu";

  pluginType = "block";

  src = "${
    fetchFromGitHub {
      owner = "netsapiensis";
      repo = "moodle-block_course_menu";
      rev = "MOODLE_34_STABLE";
      sha256 = "sha256-5f/njJFgdBVPgjuT7cFasMuqR1rpkKoO6SkACSTkcQo=";
    }
  }/${name}";
}
