{pkgs, ...}: let
in {
  environment = {
    # Selection of sysadmin tools that can come in handy
    systemPackages = with pkgs; [
      bottom
      curl
      file
      git
      htop
      jq
      ripgrep
      whois
    ];
  };

  time.timeZone = "Europe/Lisbon";

  nix = {
    # Improve nix store disk usage
    gc = {
      automatic = true;
      randomizedDelaySec = "30min";
      dates = "03:15";
    };

    # Generally useful nix option defaults
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';
  };
}
