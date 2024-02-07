{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "mergeusers";
  version = "2023061900";

  pluginType = "tool";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29477/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-qZl+XOjonLz98gi3Y9uSFpGHIycu+UTXErUUMkj3JCs=";
  };
}
