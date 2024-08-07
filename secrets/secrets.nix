let
  # Public SSH keys of users
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  raijin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7tve12K34nhNgVYZ6VgQBRrJs10v+hClpyzpXTIb/n";
  raidou = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDU8SWaX5q+dS5bnWs4ocYORUaMpYVMAGck/rbm3lRif";
  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsoczTbGY6mg9+Ti7LzMMkLvRriMjn1fbD4fTbS2VpR";
  pikachu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHxUVzXang0754ZfAv+YcNKhIILHQM28L2bd8aj0YcY";
  geoff = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICG5lKQD5jhYAT7hOLLV/3nD6IJ6BG/2OKIl/Ry5lRDg";

  users = [torvalds raijin raidou thor pikachu geoff];

  deployMachines = users ++ [];

  # Public SSH host keys of hosts
  agl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL98Q+pb8cNodccH6ta9pKDNF4NdU8GdNg0xjAOe9Aj4";
  blatta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKt+NXmZ23wpIl5QJ35xRmLPAuLcdEGC3+wgdU0qkhJV";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLCDWGT0Uv6Q2fgTTtLMDM3nTyeV5mGCIiH6zx+KI2b";
  dealer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONb9VAC3HNLUR4aTLJUVh0lgWiifYZ8BGrvrVHbzA/5";
  dei = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILHc78fOD5TKPNbpNwELDU2+ocBBt3XZ3SWZ/qETR/0J";
  dollars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWWs0qnnsgKT78qjKo7LQ4BAoiL6N9bbxuBJswHqjrw";
  dolly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUCwy4EIMsdjFtfRI0F78+WDgA7g0/5W1ZdiFcri7v2";
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
  labs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5pvNnQKZ0/a5CA25a/WVi8oqSgG2q2WKfInNP4xEpP";
  lga = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvmznnQfLbA1Jw3EPuXf48JHojUXR7tLEb/ikTG2QFB";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhiooSVjfJjmic617CS/I10ByRrWUL88FbPccBnr6KV";
  papyrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBZwTqDISf8vAcjWIvQjglURvszemLhwhLaLSbBk2c2";
  selene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBP2WaNeSaVQ5kwKHjvoWt6oTd8ymdb1I+l3SIkn8ugC";
  thomas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/SxiOeNV93iXm91x8MIEc9SW8TiksqDWQtaqnbmC6D";
  vault = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEarcNlKVSUzq6k2fTzFnMpMdGijVKvhGo/EyBvTOS4a";
  weaver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZz5HxL83BuxsJs6Qlsd1bFNRA4CH+IERgSq1Zplu8K";
in {
  # Host keys only need to be accessible by the deploy machines
  "host-keys/agl.age".publicKeys = deployMachines;
  "host-keys/blatta.age".publicKeys = deployMachines;
  "host-keys/borg.age".publicKeys = deployMachines;
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
  "host-keys/thomas.age".publicKeys = deployMachines;
  "host-keys/vault.age".publicKeys = deployMachines;
  "host-keys/weaver.age".publicKeys = deployMachines;

  # GitLab runners tokens
  "gitlab-runners/es-24-env.age".publicKeys = users ++ [labs];

  # Secrets
  "ansible-infra-vault-pass-txt.age".publicKeys = users ++ [dealer];
  "ansible-windows-vault-pass-txt.age".publicKeys = users ++ [dealer];
  "dei-glitchtip-secret-key.age".publicKeys = users ++ [dei];
  "dei-glitchtip-database-env.age".publicKeys = users ++ [dei];
  "dollars-binary-cache-key.age".publicKeys = users ++ [dollars];
  "helios-env.age".publicKeys = users ++ [selene];
  "ist-delegate-election-env.age".publicKeys = users ++ [selene];
  "moodle-agl-db-password.age".publicKeys = users ++ [agl];
  "moodle-lga-db-password.age".publicKeys = users ++ [lga];
  "munge-key.age".publicKeys = users ++ [borg labs];
  "netbox-weaver-env-py.age".publicKeys = users ++ [weaver];
  "netbox-weaver-secret-key.age".publicKeys = users ++ [weaver];
  "open-sessions-key.age".publicKeys = users ++ [labs];
  "papyrus-private-env.age".publicKeys = users ++ [papyrus];
  "papyrus-wheatley-token.age".publicKeys = users ++ [papyrus];
  "root-at-blatta-ssh-key.age".publicKeys = users ++ [blatta];
  "root-at-dei-ssh-key.age".publicKeys = users ++ [dei];
  "root-at-dealer-ssh-key.age".publicKeys = users ++ [dealer];
  "root-at-papyrus-ssh-key.age".publicKeys = users ++ [papyrus];
  "root-at-selene-ssh-key.age".publicKeys = users ++ [selene];
  "root-at-thomas-ssh-key.age".publicKeys = users ++ [thomas];
  "slurmdbd-borg-db-password.age".publicKeys = users ++ [borg];
  "transmission-labs-settings-json.age".publicKeys = users ++ [dollars dolly labs];
  "vault-cer.age".publicKeys = users ++ [vault];
  "vault-key.age".publicKeys = users ++ [vault];
  "vault-storage-hcl.age".publicKeys = users ++ [vault];
  "windows-labs-image-key.age".publicKeys = users ++ [labs];
  "wireguard-admin-private-key.age".publicKeys = users ++ [hagrid];
  "dms-prod-db-password.age".publicKeys = users ++ [dei];
}
