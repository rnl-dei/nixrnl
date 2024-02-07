{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "coderunner";
  version = "2023090800";

  pluginType = "qtype";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29972/${pluginType}_${name}_moodle43_${version}.zip";
    sha256 = "sha256-OcZe0E+qiQeBfn2PXmxEMn7CrGEi931rrAGt6IEFAY4=";
  };
}
