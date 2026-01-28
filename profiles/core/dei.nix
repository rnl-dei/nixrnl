{
  config,
  rnl-keys,
  ...
}: {
  config,
  rnl-keys,
  ...
}: {
  imports = [./rnl.nix];

  users.users.root.openssh.authorizedKeys.keys = rnl-keys.dei-keys;

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
