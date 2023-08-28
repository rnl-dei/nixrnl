{
  fetchzip,
  moodle-utils,
  ...
}:
moodle-utils.buildMoodlePlugin rec {
  name = "filtercodes";
  version = "2023050700";

  pluginType = "filter";

  src = fetchzip {
    url = "https://moodle.org/plugins/download.php/29151/${pluginType}_${name}_moodle42_${version}.zip";
    sha256 = "sha256-U2NZ8APoQNOjvIqMyMtZOvof2+5/oGxtr7aKyg0eaPk=";
  };
}
