{lib, ...}:
with lib; {
  options.rnl = {
    internalHost = mkEnableOption "Enable this if host is inaccessible from the outside";

    databases = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of databases to create at the DB Cluster";
    };

    domain = mkOption {
      type = types.str;
      readOnly = true;
      default = "rnl.tecnico.ulisboa.pt";
      description = "RNL domain";
    };

    vault = {
      url = mkOption {
        type = types.str;
        readOnly = true;
        default = "https://vault.rnl.tecnico.ulisboa.pt";
        description = "Vault server URL";
      };
    };

    database = {
      host = mkOption {
        type = types.str;
        readOnly = true;
        default = "db.rnl.tecnico.ulisboa.pt";
        description = "Database host";
      };
      port = mkOption {
        type = types.int;
        readOnly = true;
        default = 3306;
        description = "Database port";
      };
    };

    mailserver = {
      host = mkOption {
        type = types.str;
        readOnly = true;
        default = "comsat.rnl.tecnico.ulisboa.pt";
        description = "Mail server host";
      };

      port = mkOption {
        type = types.int;
        readOnly = true;
        default = 25;
        description = "Mail server port";
      };

      aliases = mkOption {
        type = attrsOf (either (listOf types.str) types.str);
        description = ''
          An attribute set of aliases to be added to the mailserver.
          The keys are the alias names, the values are either a list of
          email addresses or a single email address.
        '';
        example = {
          "info@example.com" = "user1@example.com";
          "postmaster@example.com" = "user1@example.com";
          "abuse@example.com" = "user1@example.com";
          "multi@example.com" = ["user1@example.com" "user2@example.com"];
        };
      };
    };

    emails = {
      robots = mkOption {
        type = types.string;
        description = "Email to send robot notifications to";
        default = "rnl@tecnico.ulisboa.pt";
        example = "robots@example.com";
      };

      team = mkOption {
        type = types.string;
        description = "Email to send team notifications to";
        default = "rnl@tecnico.ulisboa.pt";
        example = "team@example.com";
      };
    };

    mattermost = {
      host = mkOption {
        type = types.str;
        readOnly = true;
        default = "mattermost.rnl.tecnico.ulisboa.pt";
        description = "Mattermost host";
      };
      url = mkOption {
        type = types.str;
        readOnly = true;
        default = "https://mattermost.rnl.tecnico.ulisboa.pt";
        description = "Mattermost URL";
      };
    };

    vlans = {
      mgmt = mkOption {
        type = types.int;
        readOnly = true;
        default = 100;
        description = "Management VLAN";
      };
      admin = mkOption {
        type = types.int;
        readOnly = true;
        default = 10;
        description = "VLAN for admin network";
      };
      priv = mkOption {
        type = types.int;
        readOnly = true;
        default = 20;
        description = "VLAN for private network";
      };
      pub = mkOption {
        type = types.int;
        readOnly = true;
        default = 30;
        description = "VLAN for public network";
      };
      labs = mkOption {
        type = types.int;
        readOnly = true;
        default = 40;
        description = "VLAN for Labs network";
      };
      dmz = mkOption {
        type = types.int;
        readOnly = true;
        default = 50;
        description = "VLAN for DMZ network";
      };
      gia = mkOption {
        type = types.int;
        readOnly = true;
        default = 60;
        description = "VLAN for GIA network";
      };
      portateis = mkOption {
        type = types.int;
        readOnly = true;
        default = 70;
        description = "VLAN for Portateis network";
      };
    };
  };
}
