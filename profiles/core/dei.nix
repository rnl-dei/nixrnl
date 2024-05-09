{config, ...}: {
  imports = [./rnl.nix];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPsWjCFMvLBFUhxCG1KbsTbrDoFvUgJHmGD3rWvHHkO @prohmakas"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPEQ52WkoKA1oiXE++uLuh/zzxEvgH7oeOuQBBE0VeG pereira@cycki"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC03Nae8Zs0ncuvQMkr6A5Ia77TC6SIMn9hAofthYjS+ pereira@titiak"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIILI+0LhW+MhK3mwoqnNWjxws2qFOScx0Xhrn+ZcQB1p @vaporfly"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJT5mbxJGQEOqRE+OqNNJNsOTw+i04ywIR8gE3vjAHzg tomas@thinkpad-tomas"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwpiSXBKsqfoH5O2f/QPpJ7K7GfrumzL9LoR++Nh1Kf lucas@portatil"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYLt5UeiBkoTy2IlCmCXxiVBznJRAdNldRbZQUsylkz lucas@marte"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBc9zAF+VAj2gxmqEFJG0yBBEnUQObf2R+rMRMLGhEc4 mbenjamim@yoga"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRCi72AAIjxuDa4QEKFsy7+a7E9OOfxgctRkIy8kUoW diogo@macbook"
  ];

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
