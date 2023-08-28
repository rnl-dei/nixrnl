{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "coderunner";
  version = "2022110900";

  pluginType = "qtype";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/27875/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-OcZe0E+qiQeBfn2PXmxEMn7CrGEi931rrAGt6IEFAY4=";
  };
}
