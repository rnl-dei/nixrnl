{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config) services;
in
{
  services.fail2ban = {
    enable = true;

    extraPackages = [ pkgs.curl ];

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

    extraPackages = [ pkgs.system-sendmail ];

    # TODO: Configure abuseipdb action
    # TODO: Configure email action

    jails = {
      # Action strings need to be formatted this way, otherwise fail2ban wont recognize the multiple ban actions
      # %(action_)s is the default action (defined on jail.conf), which is "iptables-allports"

      # postfix
      postfix = mkIf services.postfix.enable {
        settings = {
          filter = "postfix";
          action = ''
            %(action_)s
               ${lib.optionalString isAbuseIPDbKeyAvailable "abuseipdb[abuseipdb_category='11,18', abuseipdb_comment='postfix']"}
          '';
        };
      };

      # nginx-botsearch
      nginx-botsearch = mkIf services.nginx.enable {
        settings = {
          filter = "nginx-botsearch";
          action = ''
            %(action_)s
               ${lib.optionalString isAbuseIPDbKeyAvailable "abuseipdb[abuseipdb_category='21', abuseipdb_comment='bot search']"}
          '';
        };
      };

      # php-url-fopen
      php-url-fopen = mkIf services.nginx.enable {
        settings = {
          filter = "php-url-fopen";
          maxretry = 1;
          action = ''
            %(action_)s
               ${lib.optionalString isAbuseIPDbKeyAvailable "abuseipdb[abuseipdb_category='21', abuseipdb_comment='php f-open() abuse']"}
          '';
        };
      };

      # sshd (sto)
      sshd = mkIf services.openssh.enable {
        settings = {
          filter = "sshd";
          action = ''
            %(action_)s
               ${lib.optionalString isAbuseIPDbKeyAvailable "abuseipdb[abuseipdb_category='18,22', abuseipdb_comment='ssh abuse']"}
          '';
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
