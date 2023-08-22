{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit (config) services;
in {
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      # RNL IPs
      "193.136.164.0/24"
      "193.136.154.0/24"
      "2001:690:2100:80::/58"
    ];

    maxretry = 3;

    # Make sure bantime is >=15m for all jails (default is 10m).
    # Abuseipdb only allows reporting the same IP once every 15m.
    bantime = "15m";
    bantime-increment = {
      enable = true;
      rndtime = "4m";
    };

    extraPackages = [pkgs.system-sendmail];

    extraSettings = {};

    # TODO: Configure abuseipdb action
    # TODO: Configure email action

    jails = {
      # postfix
      postfix = mkIf services.postfix.enable ''
        enabled = true
        filter = postfix
      '';
      # courier

      # nginx-botsearch
      nginx-botsearch = mkIf services.nginx.enable ''
        enabled = true
        filter = nginx-botsearch
      '';

      # php-url-fopen
      php-url-fopen = mkIf services.nginx.enable ''
        enabled = true
        filter = php-url-fopen
        maxretry = 1
      '';

      # sshd
      sshd = mkIf services.openssh.enable ''
        enabled = true
        filter = sshd
      '';
    };
  };

  environment.shellAliases = {
    unban-sshd = ''
      fail2ban-client set sshd unbanip $1
    '';
  };
}
