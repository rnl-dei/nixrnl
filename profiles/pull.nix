{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    flake = "gitlab:rnl/nixrnl/master?host=gitlab.rnl.tecnico.ulisboa.pt"; # Use our GitLab directly
  };
}
