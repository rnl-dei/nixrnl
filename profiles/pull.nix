{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    flake = "github:rnl-dei/nixrnl/master"; # Use GitLab mirror because the repository is private
  };
}
