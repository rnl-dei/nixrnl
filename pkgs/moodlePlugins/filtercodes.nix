{ fetchzip, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2026050200";

  pluginType = "filter";

  src = fetchzip {
    url = "https://github.com/michael-milette/moodle-filter_filtercodes/archive/63cdd1269ea8d024b405d1c5f8774ee8f4d27e58.zip";
    sha256 = "sha256-a3aR7iyuaOty08+6e7kF/kRIhgqfpp7kc661e+z3UA0=";
  };
}
