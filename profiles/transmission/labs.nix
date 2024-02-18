{
  config,
  pkgs,
  ...
}: {
  imports = [./common.nix];

  services.transmission.settings.watch-dir = pkgs.symlinkJoin {
    name = "torrents-labs";
    paths = with pkgs.rnlTorrents; [rnl-windows-labs];
  };

  services.transmission.credentialsFile = config.age.secrets."transmission-labs-settings.json".path;
  age.secrets."transmission-labs-settings.json" = {
    file = ../../secrets/transmission-labs-settings-json.age;
    owner = "transmission";
  };
}
