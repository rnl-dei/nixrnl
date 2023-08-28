let
  # Public SSH keys of users
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  users = [torvalds];

  deployMachines = users ++ [];

  # Public SSH host keys of hosts
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLCDWGT0Uv6Q2fgTTtLMDM3nTyeV5mGCIiH6zx+KI2b";
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
  lga = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvmznnQfLbA1Jw3EPuXf48JHojUXR7tLEb/ikTG2QFB";
  nexus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhiooSVjfJjmic617CS/I10ByRrWUL88FbPccBnr6KV";
  vault = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEarcNlKVSUzq6k2fTzFnMpMdGijVKvhGo/EyBvTOS4a";
in {
  # Host keys only need to be accessible by the deploy machines
  "host-keys/borg.age".publicKeys = deployMachines;
  "host-keys/hagrid.age".publicKeys = deployMachines;
  "host-keys/lga.age".publicKeys = deployMachines;
  "host-keys/nexus.age".publicKeys = deployMachines;
  "host-keys/vault.age".publicKeys = deployMachines;

  # Secrets
  "moodle-lga-db-password.age".publicKeys = users ++ [lga];
  "munge-key.age".publicKeys = users ++ [borg];
  "vault-storage-hcl.age".publicKeys = users ++ [vault];
  "wireguard-admin-private-key.age".publicKeys = users ++ [hagrid];
}
