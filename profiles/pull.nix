{...}: {
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    flake = "git+https://gitlab.rnl.tecnico.ulisboa.pt/rnl/nixrnl?ref=master";
  };
}
