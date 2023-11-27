{...}: {
  imports = [./rnl.nix];

  users.users.dei = {
    isNormalUser = true;
    description = "User to be used by grant owners of DEI team.";
    password = null; # Disable password login.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdqPxNoMvoAdSQMug5H2aMnXXQgSpEyh96dibVtxRqd @minastirith"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPsWjCFMvLBFUhxCG1KbsTbrDoFvUgJHmGD3rWvHHkO @prohmakas"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2K0/hfP9cjH/K9Q2+Kw9p/xkocw/GgfsQbz8aIM5Gk @vaporfly"
    ];
  };

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
