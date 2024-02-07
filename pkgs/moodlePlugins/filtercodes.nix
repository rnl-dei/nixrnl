{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2023112000";

  pluginType = "filter";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/30529/${pluginType}_${name}_moodle43_${version}.zip";
    sha256 = "sha256-O6QruDxYe9Nmb2gQ5epQybOL1CSLm7sKXdA5kOWGSD8=";
  };
}
