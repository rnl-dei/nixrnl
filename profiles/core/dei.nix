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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDEtMB91hKq09Ddo5gQAQKaPSVgTjynaB8gHLf0DTY7K hugo.s.pereira@tecnico.ulisboa.pt-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUjjonJmUrvapi4yxFB8vhQV5Hmf/QholYVDrZjjzkL hugsouper785@gmail.com-desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4YWMJalggVNDmlHSzIiefhAL4xChC0aV3vcgI7ut9Z mbenjamim@rola"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClrL9lcMtX0vWyN/BG63/sC89nGaceaMfjMJG6sysLE vicente@msi"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7KctWVyAfwcA4g6v9Bucvs+KWChhd2f3vRpHr3JSKY alcafache@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJiZ9mdGa3A27CMnS9y+YObLAJYkUFQJVFKrVW1D+g9 joao.sergio@apaz"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvLx61S/EayEzpVLvvFfwa58mIImMIU/PuAUes/t2RT leonardo.neves@virtus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5+deDNLsW+PjJ6fCo4WMqyQm6xA0lbfDkJ3IWg16y0 paulo.chen@alucard"
  ];

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
