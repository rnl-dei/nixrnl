{
  config,
  pkgs,
  profiles,
  lib,
  ...

}:
{
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.nixos
    type.vm
    containers.docker # required for multi-dms
    webserver
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.165";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:83::165";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.190";
    defaultGateway6.address = "2001:690:2100:83::ffff:1";
  };

  rnl.labels.location = "dredd";

  rnl.virtualisation.guest = {
    description = "VM de testes para o DEI";
    createdBy = "nuno.alves";
    maintainers = [ "dei" ];

    vcpu = 4;
    memory = 4096;

    interfaces = [ { source = "dmz"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/blatta"; } ];
  };

  rnl.internalHost = true; # Use Vault to generate certificates

  services.nginx.virtualHosts.blatta = {
    serverName = "${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations."/".root = pkgs.writeTextDir "index.html" ''
      <html>
        <body>
          <h1>Welcome to Blatta</h1>
          <a href="https://rnl.tecnico.ulisboa.pt/ca" target="_blank">Entidade certificadora da RNL</a>
          <br>
          <h2>Links</h2>
          <ul>
            <li><a href="https://dms.blatta.rnl.tecnico.ulisboa.pt">DMS (Staging)</a></li>
          </ul>
        </body>
      </html>
    '';
  };

  # Pull prod db backups from dei machine
  systemd.timers."pull-prod-db" = {
    description = "Pull DMS DB Backups timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Unit = "pull-prod-db.service";
    };
  };

  systemd.services."pull-prod-db" =
    let
      dbFile = "dms_backup_$(date +%F).sql";
    in
    {
      description = "Pull DMS DB Backups";
      script = ''
        set -euo pipefail
        ${pkgs.openssh}/bin/scp blatta@dei.rnl.tecnico.ulisboa.pt:/${dbFile} /root/dms_backups/
        ln -sf /root/dms_backups/${dbFile} /root/dms_backups/latest.sql
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

  # Services
  dei.dms = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSDnfYmzk0zCktsKjRAphZavsDwXG/ymq+STFff1Zy/" # GitLab CI
    ];
    sites.default.serverName = "dms.${config.networking.fqdn}";
  };

  dei.multi-dms = {
    enable = true;
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSDnfYmzk0zCktsKjRAphZavsDwXG/ymq+STFff1Zy/" # GitLab CI
    ];
  };

  # ODEIO
  dei.odeio = {
    builds.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHIpnBeT+Pe1LZt1lAmQzNLCxHSc/8Md1qrUCzfziuBf odeio-CI" # GitLab CI
    ];
    sites.default.serverName = "odeio.${config.networking.fqdn}";
  };
  rnl.db-cluster = {
    ensureDatabases = [ "dms_blatta" ];
    ensureUsers = [
      {
        name = "dms";
        ensurePermissions = {
          "dms_blatta.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  dei.phdms.sites.default.serverName = "phdms.${config.networking.fqdn}";

  rnl.githook = {
    enable = true;
    hooks = {
      phdms = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:/dei/PhDMS.git";
        path = config.dei.phdms.sites.default.stateDir;
        directoryMode = "0755";
      };
    };
  };

  systemd.tmpfiles.rules = [ "d /root/.ssh 0755 root root" ];
  age.secrets."root-at-blatta-ssh.key" = {
    file = ../secrets/root-at-blatta-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  services.postgresql = {
    enable = true;
    authentication = ''
      local phdms phdms trust
    '';
    ensureDatabases = [ "phdms" ];
    ensureUsers = [
      {
        name = "root";
        ensureClauses.superuser = true;
      }
      {
        name = "phdms";
        ensureDBOwnership = true;
      }
    ];
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "dms" ];
    ensureUsers = [
      {
        name = "dms";
        ensurePermissions = {
          "dms.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # MailHog
  services.mailhog.enable = true;
  # NOTE: conflito entre core.rnl sendmail e o mailhog
  # forcing o module do mailhog (https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/mail/mailhog.nix)
  services.mail.sendmailSetuidWrapper = {
    source = lib.mkForce (
      lib.getExe (
        pkgs.writeShellScriptBin "mailhog-sendmail" ''
          exec ${lib.getExe pkgs.mailhog} sendmail $@
        ''
      )
    );
    owner = lib.mkForce "nobody";
    group = lib.mkForce "nogroup";
  };

  services.nginx.virtualHosts.mailhog = {
    serverName = "mailhog.${config.networking.fqdn}";
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.mailhog.uiPort}";
      proxyWebsockets = true;
    };
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "random-logout-message" ''
      # Select random string from list
      ${pkgs.fortune}/bin/fortune | ${pkgs.cowsay}/bin/cowsay -f "$(ls ${pkgs.cowsay}/share/cowsay/cows | ${pkgs.gnugrep}/bin/grep ".cow$" | ${pkgs.toybox}/bin/shuf -n 1)" | ${pkgs.lolcat}/bin/lolcat -f
    '')
  ];

  # Add specific ssh key for thesis student
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkgxDz3Z1k23/QMM1vYTcb2BvGb4/X3NmoxwEZM4Ntb joao_ferreira"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID0doCaLhrkoMn8Rs52XhiBmqWd0V1l2vUYX0dlrVWfe nuno.briers.dendas@tecnico.ulisboa.pt"
  ];
}
