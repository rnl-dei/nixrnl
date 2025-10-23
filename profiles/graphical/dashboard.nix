{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  # Create RNL user without full permissions
  users.users.rnl = {
    isNormalUser = true;
    description = "RNL user to run firefox and other stuff";
  };

  services.xserver = {
    windowManager.openbox.enable = true;

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
  services.displayManager.autoLogin = {
    enable = true;
    user = "rnl";
  };

  xdg.autostart.enable = true;

  environment.etc."xdg/autostart/firefox.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Firefox
    Exec=${pkgs.firefox}/bin/firefox --kiosk
  '';

  environment.systemPackages = with pkgs; [
    firefox
    kdePackages.konsole
  ]; # keep terminal installed to reopen programs in hagrid

  services.unclutter-xfixes = {
    enable = true;
    timeout = 10;
  };

  programs.firefox = {
    enable = true;
    policies = {
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      TranslateEnabled = false;

      ExtensionSettings =
        let
          moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
        in
        {
          "uBlock0@raymondhill.net" = {
            install_url = moz "ublock-origin";
            installation_mode = "force_installed";
          };
          "tabrotator@davidfichtmueller.de" = {
            install_url = moz "tab-rotator";
            installation_mode = "force_installed";
          };
        };
    };
  };
}
