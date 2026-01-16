{ config, ... }:
{
  imports = [ ./rnl.nix ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDEtMB91hKq09Ddo5gQAQKaPSVgTjynaB8gHLf0DTY7K hugo.s.pereira@tecnico.ulisboa.pt-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClrL9lcMtX0vWyN/BG63/sC89nGaceaMfjMJG6sysLE vicente@msi"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7KctWVyAfwcA4g6v9Bucvs+KWChhd2f3vRpHr3JSKY alcafache@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJiZ9mdGa3A27CMnS9y+YObLAJYkUFQJVFKrVW1D+g9 joao.sergio@apaz"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHvLx61S/EayEzpVLvvFfwa58mIImMIU/PuAUes/t2RT leonardo.neves@virtus"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5+deDNLsW+PjJ6fCo4WMqyQm6xA0lbfDkJ3IWg16y0 paulo.chen@alucard"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFlyAPbpCY33eSGsbohPS824PvrEYUGf2v2ORuKBfIo6 miguel.carvalho@mlc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2DRBpPu3BlNBr9wL9l51/SGY9xMEbaWIuRHWwYTfP+ zmws@nixos"
  ];

  rnl.githook.emailDestination = "robots-dei@${config.rnl.domain}";

  # Override the default label "rnl" with "dei"
  rnl.labels.core = "dei";
}
