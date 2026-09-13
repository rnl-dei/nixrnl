{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2026050200";

  pluginType = "filter";

  src = fetchFromGitHub {
    owner = "michael-milette";
    repo = "moodle-filter_filtercodes";
    rev = "v2.7.3";
    sha256 = "sha256-uEw3z4/OJjSiPLYJnM5+l4X5XA+BeSWpre3mlTDe2YI=";
  };
}
