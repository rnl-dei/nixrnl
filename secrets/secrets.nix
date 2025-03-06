let
  # Public SSH keys of users
  ## RNL
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  raijin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7tve12K34nhNgVYZ6VgQBRrJs10v+hClpyzpXTIb/n";
  raidou = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDU8SWaX5q+dS5bnWs4ocYORUaMpYVMAGck/rbm3lRif";
  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsoczTbGY6mg9+Ti7LzMMkLvRriMjn1fbD4fTbS2VpR";
  pikachu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHxUVzXang0754ZfAv+YcNKhIILHQM28L2bd8aj0YcY";
  geoff = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICG5lKQD5jhYAT7hOLLV/3nD6IJ6BG/2OKIl/Ry5lRDg";
  aurelius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrco+nZ1DgpsNHntTzMeo626GglxwLKks3XL82XD0kZ";
  lilb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjU844+uGu7dgVOE4YHU6+VWd/PgX5J2C0fcNnVyeYi";

  ## DEI
  sazed = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7foe85vNDLm0vyVVugR8ThC1VjHuAtqAQ/K2AAVE9r"; # rafael.girao
  prohmakas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPsWjCFMvLBFUhxCG1KbsTbrDoFvUgJHmGD3rWvHHkO"; # jose.pereira

  users = [
    torvalds
    raijin
    raidou
    thor
    pikachu
    geoff
    aurelius
    lilb
  ];

  deiUsers = [
    sazed
    prohmakas
  ];

  deployMachines = users ++ [ ];

  # Public SSH host keys of hosts
  agl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL98Q+pb8cNodccH6ta9pKDNF4NdU8GdNg0xjAOe9Aj4";
  blatta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKt+NXmZ23wpIl5QJ35xRmLPAuLcdEGC3+wgdU0qkhJV";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLCDWGT0Uv6Q2fgTTtLMDM3nTyeV5mGCIiH6zx+KI2b";
  caixote = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDqUCaBZ5e2e8k05ba/17fAYdDjXU3dTx/D5rg3JISu";
  dealer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONb9VAC3HNLUR4aTLJUVh0lgWiifYZ8BGrvrVHbzA/5";
  dei = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHc78fOD5TKPNbpNwELDU2+ocBBt3XZ3SWZ/qETR/0J";
  dollars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWWs0qnnsgKT78qjKo7LQ4BAoiL6N9bbxuBJswHqjrw";
  dolly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUCwy4EIMsdjFtfRI0F78+WDgA7g0/5W1ZdiFcri7v2";
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
  labs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5pvNnQKZ0/a5CA25a/WVi8oqSgG2q2WKfInNP4xEpP";
  lga = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvmznnQfLbA1Jw3EPuXf48JHojUXR7tLEb/ikTG2QFB";
  #nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhiooSVjfJjmic617CS/I10ByRrWUL88FbPccBnr6KV";
  papyrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBZwTqDISf8vAcjWIvQjglURvszemLhwhLaLSbBk2c2";
  selene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBP2WaNeSaVQ5kwKHjvoWt6oTd8ymdb1I+l3SIkn8ugC";
  tardis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGOUuCvrnWbXGFZAl5n7W/IGgwmNauGUBzY1hdeIkoY";
  thomas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/SxiOeNV93iXm91x8MIEc9SW8TiksqDWQtaqnbmC6D";
  vault = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEarcNlKVSUzq6k2fTzFnMpMdGijVKvhGo/EyBvTOS4a";
  weaver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZz5HxL83BuxsJs6Qlsd1bFNRA4CH+IERgSq1Zplu8K";
  www = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO5cj7QcYEz9cSmbQS1ZbmDjQUVdsT9AsmyJdFbZNOg/ www";
in
{
  # Host keys only need to be accessible by the deploy machines
  "host-keys/agl.age".publicKeys = deployMachines;
  "host-keys/blatta.age".publicKeys = deployMachines;
  "host-keys/borg.age".publicKeys = deployMachines;
  "host-keys/caixote.age".publicKeys = deployMachines;
  "host-keys/dealer.age".publicKeys = deployMachines;
  "host-keys/dei.age".publicKeys = deployMachines;
  "host-keys/dollars.age".publicKeys = deployMachines;
  "host-keys/dolly.age".publicKeys = deployMachines;
  "host-keys/hagrid.age".publicKeys = deployMachines;
  "host-keys/labs.age".publicKeys = deployMachines;
  "host-keys/lga.age".publicKeys = deployMachines;
  "host-keys/nexus.age".publicKeys = deployMachines;
  "host-keys/papyrus.age".publicKeys = deployMachines;
  "host-keys/selene.age".publicKeys = deployMachines;
  "host-keys/tardis.age".publicKeys = deployMachines;
  "host-keys/thomas.age".publicKeys = deployMachines;
  "host-keys/vault.age".publicKeys = deployMachines;
  "host-keys/weaver.age".publicKeys = deployMachines;
  "host-keys/www.age".publicKeys = deployMachines;

  # GitLab runners tokens
  "gitlab-runners/es-25-env.age".publicKeys = users ++ [ labs ];

  # Secrets
  "abuseipdb-api-key.age".publicKeys = users ++ [
    hagrid
    lga
  ];
  "ansible-infra-vault-pass-txt.age".publicKeys = users ++ [ dealer ];
  "ansible-windows-vault-pass-txt.age".publicKeys = users ++ [ dealer ];
  "dei-dei-docker-config.json.age".publicKeys = users ++ deiUsers ++ [ dei ];
  "dei-glitchtip-database-env.age".publicKeys = users ++ deiUsers ++ [ dei ];
  "dei-glitchtip-secret-key.age".publicKeys = users ++ deiUsers ++ [ dei ];
  "dei-photoprism-admin-password.age".publicKeys = users ++ deiUsers ++ [ dei ];
  "dei-photoprism-oidc-secret.age".publicKeys = users ++ deiUsers ++ [ dei ];
  "dms-prod-db-password.age".publicKeys = users ++ [ dei ];
  "dollars-binary-cache-key.age".publicKeys = users ++ [ dollars ];
  "helios-env.age".publicKeys = users ++ [ selene ];
  "ist-delegate-election-env.age".publicKeys = users ++ [ selene ];
  "moodle-agl-db-password.age".publicKeys = users ++ [ agl ];
  "moodle-lga-db-password.age".publicKeys = users ++ [ lga ];
  "munge-key.age".publicKeys = users ++ [
    borg
    labs
  ];
  "weaver-rnl-docker-config.json.age".publicKeys = users ++ [ weaver ];
  "netbox-weaver-env-py.age".publicKeys = users ++ [ weaver ];
  "netbox-weaver-secret-key.age".publicKeys = users ++ [ weaver ];
  "open-sessions-key.age".publicKeys = users ++ [ labs ];
  "open-sessions-db-uri.age".publicKeys = users ++ [ www ];
  "papyrus-private-env.age".publicKeys = users ++ [ papyrus ];
  "papyrus-wheatley-token.age".publicKeys = users ++ [ papyrus ];
  "root-at-blatta-ssh-key.age".publicKeys = users ++ [ blatta ];
  "root-at-dealer-ssh-key.age".publicKeys = users ++ [ dealer ];
  "root-at-dei-ssh-key.age".publicKeys = users ++ [ dei ];
  "root-at-papyrus-ssh-key.age".publicKeys = users ++ [ papyrus ];
  "root-at-selene-ssh-key.age".publicKeys = users ++ [ selene ];
  "root-at-thomas-ssh-key.age".publicKeys = users ++ [ thomas ];
  "root-at-www-ssh-key.age".publicKeys = users ++ [ www ];
  "roundcube-www-db-password.age".publicKeys = users ++ [ www ];
  "slurmdbd-borg-db-password.age".publicKeys = users ++ [ borg ];
  "syncoid-at-caixote-ssh-key.age".publicKeys = users ++ [ caixote ];
  "tardis-grafana-env.age".publicKeys = users ++ [ tardis ];
  "tardis-healthchecksio-url.age".publicKeys = users ++ [ tardis ];
  "tardis-snmp-exporter-env.age".publicKeys = users ++ [ tardis ];
  "transmission-labs-settings-json.age".publicKeys = users ++ [
    dollars
    dolly
    labs
  ];
  "vault-cer.age".publicKeys = users ++ [ vault ];
  "vault-key.age".publicKeys = users ++ [ vault ];
  "vault-storage-hcl.age".publicKeys = users ++ [ vault ];
  "windows-labs-image-key.age".publicKeys = users ++ [ labs ];
  "wireguard-admin-private-key.age".publicKeys = users ++ [ hagrid ];
  "www-tv-client-secret-env.age".publicKeys = users ++ [ www ];
  "www-tv-cms-secret-env.age".publicKeys = users ++ [ www ];
}
