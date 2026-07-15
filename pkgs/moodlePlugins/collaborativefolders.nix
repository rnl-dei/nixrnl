{ fetchFromGitHub, moodle-utils, ... }:
moodle-utils.buildMoodlePlugin rec {
  name = "collaborativefolders";
  pluginType = "mod";

  src = fetchFromGitHub {
    owner = "learnweb";
    repo = "moodle-mod_collaborativefolders";
    rev = "v3.9-r1";
    sha256 = "sha256-LwdGZIdJFK9aKgZupRPpW02JzTpepURPvLvi3RS0feU=";
  };
}
