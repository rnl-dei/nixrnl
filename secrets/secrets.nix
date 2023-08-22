let
  # Public SSH keys of users
  torvalds = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/rKlyYzFscsso96forbN2Y6IJ5yitGPS9Nci5n9vps";
  users = [torvalds];

  deployMachines = users ++ [];

  # Public SSH host keys of hosts
  hagrid = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9MnzWv7ulk6w3YTEIW5XuW6CzpMd43qFYpfsQ3zt7k";
in {
  # Host keys only need to be accessible by the deploy machines
  "host-keys/hagrid.age".publicKeys = deployMachines;

  # Secrets
  "wireguard-admin-private-key.age".publicKeys = users ++ [hagrid];
}
