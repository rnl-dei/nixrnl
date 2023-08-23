let
  # Public SSH keys of users
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  users = [torvalds];

  deployMachines = users ++ [];

  # Public SSH host keys of hosts
  agl = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL98Q+pb8cNodccH6ta9pKDNF4NdU8GdNg0xjAOe9Aj4";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLCDWGT0Uv6Q2fgTTtLMDM3nTyeV5mGCIiH6zx+KI2b";
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
  labs = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5pvNnQKZ0/a5CA25a/WVi8oqSgG2q2WKfInNP4xEpP";
  lga = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvmznnQfLbA1Jw3EPuXf48JHojUXR7tLEb/ikTG2QFB";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhiooSVjfJjmic617CS/I10ByRrWUL88FbPccBnr6KV";
  vault = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEarcNlKVSUzq6k2fTzFnMpMdGijVKvhGo/EyBvTOS4a";
  papyrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBZwTqDISf8vAcjWIvQjglURvszemLhwhLaLSbBk2c2";
in {
  # Host keys only need to be accessible by the deploy machines
  "host-keys/agl.age".publicKeys = deployMachines;
  "host-keys/borg.age".publicKeys = deployMachines;
  "host-keys/hagrid.age".publicKeys = deployMachines;
  "host-keys/labs.age".publicKeys = deployMachines;
  "host-keys/lga.age".publicKeys = deployMachines;
  "host-keys/nexus.age".publicKeys = deployMachines;
  "host-keys/papyrus.age".publicKeys = deployMachines;
  "host-keys/vault.age".publicKeys = deployMachines;

  # Secrets
  "moodle-agl-db-password.age".publicKeys = users ++ [agl];
  "moodle-lga-db-password.age".publicKeys = users ++ [lga];
  "munge-key.age".publicKeys = users ++ [borg labs];
  "papyrus-private-env.age".publicKeys = users ++ [papyrus];
  "vault-storage-hcl.age".publicKeys = users ++ [vault];
  "wireguard-admin-private-key.age".publicKeys = users ++ [hagrid];
}
