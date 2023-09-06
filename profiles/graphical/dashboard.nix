{pkgs, ...}: {
  imports = [./common.nix];

  # Create RNL user without full permissions
  users.users.rnl = {
    isNormalUser = true;
    description = "RNL user to run chromium and other stuff";
  };

  services.xserver = {
    windowManager.openbox.enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "rnl";
    };
    monitorSection = ''
      Option "DPMS" "false"
    '';
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
  };

  xdg.autostart.enable = true;
  environment.etc.autostartChromium = {
    source = "${pkgs.chromium}/share/applications/chromium-browser.desktop";
    target = "xdg/autostart/chromium-browser.desktop";
  };

  environment.systemPackages = with pkgs; [chromium];

  programs.chromium = {
    enable = true;
    extensions = [
      "pjgjpabbgnnoohijnillgbckikfkbjed" # Tab Rotate
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
    ];
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
    };
  };
}
