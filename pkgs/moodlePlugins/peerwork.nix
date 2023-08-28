{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "peerwork";
  version = "2022062600";

  pluginType = "mod";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/27509/${pluginType}_${name}_moodle41_${version}.zip";
    sha256 = "sha256-OnQpxIb26UKWebfsuBn+/yrar1pIFQxgMjc2RoMb9EE=";
  };
}
