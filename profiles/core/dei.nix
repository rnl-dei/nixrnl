{ config, ... }:
{
  imports = [ ./rnl.nix ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPsWjCFMvLBFUhxCG1KbsTbrDoFvUgJHmGD3rWvHHkO @prohmakas"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPEQ52WkoKA1oiXE++uLuh/zzxEvgH7oeOuQBBE0VeG pereira@cycki"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC03Nae8Zs0ncuvQMkr6A5Ia77TC6SIMn9hAofthYjS+ pereira@titiak"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwpiSXBKsqfoH5O2f/QPpJ7K7GfrumzL9LoR++Nh1Kf lucas@portatil"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYLt5UeiBkoTy2IlCmCXxiVBznJRAdNldRbZQUsylkz lucas@marte"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBc9zAF+VAj2gxmqEFJG0yBBEnUQObf2R+rMRMLGhEc4 mbenjamim@yoga"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRCi72AAIjxuDa4QEKFsy7+a7E9OOfxgctRkIy8kUoW diogo@macbook"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEwOBxayZyd/zGYyoTRN2rdIQM71nzVT3lISg2pNfrZRAAAABHNzaDo= rafael.girao@Yubikey"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJvkSRd4B8oEvmXI5uduJtrV4GkRc/f1PFaezQ3wobn08apvaTGHLrNPqgqzv+QwNppWkwSX0j2fNqt2dsUmcbw= rafael.girao@sazed2[TPM]"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBxyt2Uhru+PIf9SKRF96AW05P9WuyR7NKbS6OZyElNjOT+1qmkeL82+7B5qeHsACA3ZRo4svorIS1Q8khLmexk= rafael.girao@vin-TPM"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1lwuhiBZjUIzFikFCrzyp1jppOZSvlyc1/JZDvvqgD simao.sanguinho@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJYSbX6p2JOTjroVejNWYndyf9LX/yzDyHO8nY32JGf sanguinho@nixos"
  ];

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
