let
  # Public SSH keys of users
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  aurelius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBe+xU3BXFYFVoKNAFXG/amC0fhua6S5eK2g6Y+MkwYu";
  doppler = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHQiRYpOfTpddexkndt7d3Bw2wS/wLKKjs4526pJOdM";
  raijin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7tve12K34nhNgVYZ6VgQBRrJs10v+hClpyzpXTIb/n";
  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsoczTbGY6mg9+Ti7LzMMkLvRriMjn1fbD4fTbS2VpR";

  users = [torvalds aurelius doppler raijin thor];

  deployMachines = users ++ [];

  # Public SSH host keys of hosts
  agl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL98Q+pb8cNodccH6ta9pKDNF4NdU8GdNg0xjAOe9Aj4";
  blatta = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKt+NXmZ23wpIl5QJ35xRmLPAuLcdEGC3+wgdU0qkhJV";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLCDWGT0Uv6Q2fgTTtLMDM3nTyeV5mGCIiH6zx+KI2b";
  dollars = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWWs0qnnsgKT78qjKo7LQ4BAoiL6N9bbxuBJswHqjrw";
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
  labs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5pvNnQKZ0/a5CA25a/WVi8oqSgG2q2WKfInNP4xEpP";
  lga = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvmznnQfLbA1Jw3EPuXf48JHojUXR7tLEb/ikTG2QFB";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhiooSVjfJjmic617CS/I10ByRrWUL88FbPccBnr6KV";
  papyrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBZwTqDISf8vAcjWIvQjglURvszemLhwhLaLSbBk2c2";
  selene = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBP2WaNeSaVQ5kwKHjvoWt6oTd8ymdb1I+l3SIkn8ugC";
  thomas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/SxiOeNV93iXm91x8MIEc9SW8TiksqDWQtaqnbmC6D";
  vault = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEarcNlKVSUzq6k2fTzFnMpMdGijVKvhGo/EyBvTOS4a";
in {
  # Host keys only need to be accessible by the deploy machines
  "host-keys/agl.age".publicKeys = deployMachines;
  "host-keys/blatta.age".publicKeys = deployMachines;
  "host-keys/borg.age".publicKeys = deployMachines;
  "host-keys/dollars.age".publicKeys = deployMachines;
  "host-keys/hagrid.age".publicKeys = deployMachines;
  "host-keys/labs.age".publicKeys = deployMachines;
  "host-keys/lga.age".publicKeys = deployMachines;
  "host-keys/nexus.age".publicKeys = deployMachines;
  "host-keys/papyrus.age".publicKeys = deployMachines;
  "host-keys/selene.age".publicKeys = deployMachines;
  "host-keys/thomas.age".publicKeys = deployMachines;
  "host-keys/vault.age".publicKeys = deployMachines;

  # Secrets
  "dollars-binary-cache-key.age".publicKeys = users ++ [dollars];
  "ist-delegate-election-env.age".publicKeys = users ++ [selene];
  "moodle-agl-db-password.age".publicKeys = users ++ [agl];
  "moodle-lga-db-password.age".publicKeys = users ++ [lga];
  "munge-key.age".publicKeys = users ++ [borg labs];
  "open-sessions-key.age".publicKeys = users ++ [labs];
  "papyrus-private-env.age".publicKeys = users ++ [papyrus];
  "root-at-blatta-ssh-key.age".publicKeys = users ++ [blatta];
  "slurmdbd-borg-db-password.age".publicKeys = users ++ [borg];
  "root-at-thomas-ssh-key.age".publicKeys = users ++ [thomas];
  "vault-cer.age".publicKeys = users ++ [vault];
  "vault-key.age".publicKeys = users ++ [vault];
  "vault-storage-hcl.age".publicKeys = users ++ [vault];
  "windows-labs-image-key.age".publicKeys = users ++ [labs];
  "wireguard-admin-private-key.age".publicKeys = users ++ [hagrid];
}
