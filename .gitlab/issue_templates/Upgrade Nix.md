## NixOS upgrade

- What is the old version?
- What is the new version?

## Hosts

Hosts in general should be upgraded by the order stated, which accounts for test and deployment machine

### Labs

[ ] cirrus
[ ] All labs (lab3 should be the last due to Nvidia trash.)
[ ] dollars
[ ] dolly
[ ] borg

### Hypervisors

[ ] atlas
[ ] chapek
[ ] dredd
[ ] hive
[ ] neo
[ ] zion

### Core

[ ] db0
[ ] db1
[ ] db2
[ ] vault
[ ] ns1
[ ] ns2
[ ] hagrid
[ ] papyrus
[ ] tardis
[ ] dealer
[ ] weaver
[ ] doorstep
[ ] caixote
[ ] www

### Moodle

[ ] agl
[ ] lga

### Dei

[ ] blatta
[ ] dei
[ ] booble

### Gitlab
(Both are forward and backward compatible between each other. Given GitLab is the most disastrous service of ours to lose data, please backup before updating!)
Before upgrading, plan the upgrade path for the GitLab instance. Use https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/. You'll need to do multiple NixOS overlays in order to reach the target version. 
See [Wiki Link](https://worksinprogress.co/) for more information.
[ ] gitlab (when transition to nix is concluded)
[ ] operario

### Other Services

[ ] nexus1
[ ] nexus2
[ ] selene
[ ] hedgedoc
[ ] kutt
