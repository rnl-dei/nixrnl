{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2024050100";

  pluginType = "filter";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/31902/${pluginType}_${name}_moodle44_${version}.zip";
    sha256 = "sha256-6Z+9P/ax1UKxuaoNnbEHPK3jrU5JvgjsPiQIwmF4Xac=";
  };
}
