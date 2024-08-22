{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit (config) services;
in {
  age.secrets."abuseipdb-api-key".file = ../secrets/abuseipdb-api-key.age;

  systemd.services.fail2ban.serviceConfig.EnvironmentFile = config.age.secrets."abuseipdb-api-key".path;

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

    jails = {
      # postfix
      postfix = mkIf services.postfix.enable {
        settings = {
          filter = "postfix";
          action = ''abuseipdb[abuseipdb_apikey=$ABUSEIPDB_KEY, abuseipdb_category="11,18", abuseipdb_comment="postfix (h)"]'';
        };
      };
      # courier

      # nginx-botsearch
      nginx-botsearch = mkIf services.nginx.enable {
        settings = {
          filter = "nginx-botsearch";
          action = ''abuseipdb[abuseipdb_apikey=$ABUSEIPDB_KEY, abuseipdb_category="21", abuseipdb_comment="bot search (h)"]'';
        };
      };

      # php-url-fopen
      php-url-fopen = mkIf services.nginx.enable {
        settings = {
          filter = "php-url-fopen";
          maxretry = 1;
          action = ''abuseipdb[abuseipdb_apikey=$ABUSEIPDB_KEY, abuseipdb_category="21", abuseipdb_comment="php f-open() abuse (h)"]'';
        };
      };

      # sshd (sto)
      sshd = mkIf services.openssh.enable {
        settings = {
          filter = "sshd";
          action = ''abuseipdb[abuseipdb_apikey=%($ABUSEIPDB_KEY)s, abuseipdb_category="18,22", abuseipdb_comment="ssh abuse (h)"]'';
        };
      };
    };
  };

  environment.shellAliases = {
    unban-sshd = ''
      fail2ban-client set sshd unbanip $1
    '';
  };
}
