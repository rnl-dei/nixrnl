{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.rnl.wallpaper;
in {
  options.rnl.wallpaper = {
    enable = mkEnableOption "RNL Wallpaper";
    url = mkOption {
      type = types.str;
      default = "https://source.unsplash.com/random/1920x1080";
      description = "URL to fetch wallpaper from";
    };
    path = mkOption {
      type = types.path;
      default = "/usr/share/backgrounds/rnl-wallpaper.png";
      description = "Path to save wallpaper to";
    };
    defaultWallpaper = mkOption {
      type = types.path;
      default = pkgs.rnlWallpapers.default;
      description = "Path to default wallpaper";
    };
  };

  config = mkIf cfg.enable {
    systemd.services."rnl-wallpaper" = {
      description = "RNL Wallpaper";
      wantedBy = ["graphical.target"];
      startAt = "*-*-* 4:00:00"; # Run every day at 4am
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        #!/usr/bin/env bash
        set -euo pipefail

        url="${cfg.url}"
        path="${cfg.path}"
        defaultWallpaper="${cfg.defaultWallpaper}"

        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$path")"

        # Download wallpaper
        ${pkgs.curl}/bin/curl -sL "$url" -o "$path" || cp "$defaultWallpaper" "$path"
        chmod 644 "$path"

        # Restart display manager if no one is logged in on graphical tty
        if [[ -z "$(who | grep tty${toString config.services.xserver.tty})" ]]; then
          systemctl restart display-manager
        fi
      '';
    };
  };
}
