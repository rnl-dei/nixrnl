{config, ...}: {
  services.xserver.enable = true;

  # RNL Wallpaper
  rnl.wallpaper = {
    enable = true;
    url = "https://wallpaper.rnl.tecnico.ulisboa.pt/";
  };

  # Display Manager: LightDM
  services.xserver.displayManager.lightdm = {
    enable = true;
    extraSeatDefaults = "greeter-hide-users=true";
    extraConfig = "user-authority-in-system-dir=true";
    background = config.rnl.wallpaper.path;
  };

  # Desktop Manager: Cinnamon
  services.xserver.desktopManager.cinnamon = {
    enable = true;
    # TODO: Lock some dconf settings

    extraGSettingsOverrides = ''
      # Change default background
      [org.cinnamon.desktop.background]
      picture-uri='file://${config.rnl.wallpaper.path}'
    '';
  };

  programs.dconf.enable = true;
}
