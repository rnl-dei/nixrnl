{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "mergeusers";
  version = "2023040402";

  pluginType = "tool";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/28943/${pluginType}_${name}_moodle41_${version}.zip";
    sha256 = "sha256-SGM+kuHsFw+p30O8EB1fz1oWnB5q/60bA3+cliDlYII=";
  };
}
