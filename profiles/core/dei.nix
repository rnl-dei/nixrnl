{ config, ... }:
{
  imports = [ ./rnl.nix ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPsWjCFMvLBFUhxCG1KbsTbrDoFvUgJHmGD3rWvHHkO @prohmakas"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPEQ52WkoKA1oiXE++uLuh/zzxEvgH7oeOuQBBE0VeG pereira@cycki"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC03Nae8Zs0ncuvQMkr6A5Ia77TC6SIMn9hAofthYjS+ pereira@titiak"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC85hF9SnRkDs8XNStdFp4rbbaIcgsLH/BzngQQPpiWO lucks@mac"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYLt5UeiBkoTy2IlCmCXxiVBznJRAdNldRbZQUsylkz lucas@marte"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBc9zAF+VAj2gxmqEFJG0yBBEnUQObf2R+rMRMLGhEc4 mbenjamim@yoga"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1lwuhiBZjUIzFikFCrzyp1jppOZSvlyc1/JZDvvqgD simao.sanguinho@macbook"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJYSbX6p2JOTjroVejNWYndyf9LX/yzDyHO8nY32JGf sanguinho@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDEtMB91hKq09Ddo5gQAQKaPSVgTjynaB8gHLf0DTY7K hugo.s.pereira@tecnico.ulisboa.pt-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUjjonJmUrvapi4yxFB8vhQV5Hmf/QholYVDrZjjzkL hugsouper785@gmail.com-desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4YWMJalggVNDmlHSzIiefhAL4xChC0aV3vcgI7ut9Z mbenjamim@rola"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClrL9lcMtX0vWyN/BG63/sC89nGaceaMfjMJG6sysLE vicente@msi"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjglLGS9X3of/2ZpM9jTCgT7QYPFK4VSVFmCJ81UhUD vicente.duarte@tecnico.ulisboa.pt"
  ];

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
