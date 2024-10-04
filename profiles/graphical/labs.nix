{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./common.nix ];

  # RNL Wallpaper
  rnl.wallpaper = {
    enable = true;
    url = "https://wallpaper.${config.rnl.domain}/";
  };

  # Display Manager: LightDM
  services.xserver.displayManager.lightdm = {
    enable = true;
    extraSeatDefaults = "greeter-hide-users=true";
    extraConfig = "user-authority-in-system-dir=true";
    background = config.rnl.wallpaper.path;
  };

  environment.cinnamon.excludePackages = with pkgs; [ networkmanagerapplet ];
  programs.nm-applet.enable = lib.mkForce false;

  # Desktop Manager: Cinnamon
  services.xserver.desktopManager.cinnamon = {
    enable = true;
    # TODO: Lock some dconf settings

    extraGSettingsOverrides = ''
      # Change default background
      [org.cinnamon.desktop.background]
      picture-uri='file://${config.rnl.wallpaper.path}'

      [org.cinnamon]
      favorite-apps=['firefox.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop', 'code.desktop']
      enabled-applets=['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:separator@cinnamon.org:1', 'panel1:left:2:grouped-window-list@cinnamon.org:2', 'panel1:right:0:systray@cinnamon.org:3', 'panel1:right:1:xapp-status@cinnamon.org:4', 'panel1:right:2:notifications@cinnamon.org:5', 'panel1:right:4:removable-drives@cinnamon.org:7', 'panel1:right:5:keyboard@cinnamon.org:8', 'panel1:right:8:sound@cinnamon.org:11', 'panel1:right:10:calendar@cinnamon.org:13', 'panel1:right:11:cornerbar@cinnamon.org:14']

      [org.cinnamon.theme]
      name='Mint-Y-Dark-Aqua'

      [org.cinnamon.desktop.interface]
      cursor-theme='Adwaita'
      gtk-theme='Mint-Y-Dark-Aqua'
      icon-theme='Mint-Y-Dark-Aqua'

      [org.nemo.desktop]
      home-icon-visible=true
      trash-icon-visible=true
    '';
  };

  # Automatically log users out after 4 hours of inactivity
  services.xserver.xautolock = {
    enable = true;

    time = 240; # 4 hours
    locker = "${pkgs.systemd}/bin/loginctl terminate-session $XDG_SESSION_ID";

    enableNotifier = true;
    notify = 60;
    # Requires double escaping the quotes otherwise it breaks the systemd unit file and the service won't start
    notifier = "${pkgs.libnotify}/bin/notify-send \\'Logging out for inactivity in 60 seconds...\\'";
  };

  xdg.mime.defaultApplications = {
    # Web
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    # Images
    "image/jpeg" = "xviewer.desktop";
    "image/jpg" = "xviewer.desktop";
    "image/png" = "xviewer.desktop";
    "image/gif" = "xviewer.desktop";
    # Documents
    "inode/directory" = "nemo.desktop";
    "application/pdf" = "xreader.desktop";
    "text/plain" = "xed.desktop";
  };

  programs.dconf.enable = true;

  environment.shellInit = ''
    # When users first login into the new NixOS in the labs,
    # clean up their home configurations.
    if echo "$USER" | grep -E "^ist[0-9]+$" 2>&1 >/dev/null; then
      if [ -d ~ ] && [ -w ~ ]; then
        if ! [ -e ~/.config/rnl-home-config-1.0 ]; then
          (
              set -e # bail on first error

              echo "Old config detected"
              echo "Backing up old ~/.config"
              mv ~/.config ~/".config-$(date +"%F").bak"

              echo "Resetting dconf parameters"
              dconf reset -f /org/

              echo "Saving state"
              mkdir -p ~/.config
              touch ~/.config/rnl-home-config-1.0
          ) > ~/"rnl-config-migrate-$(date +"%F").log" 2>&1
        fi
      fi
    fi
  '';
}
