{...}: {
  imports = [./rnl.nix];

  users.users.dei = {
    isNormalUser = true;
    description = "User to be used by grant owners of DEI team.";
    password = null; # Disable password login.
  };

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
