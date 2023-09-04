{...}: {
  imports = [./common.nix];

  services.slurm.client.enable = true;

  # Ensure slurmd does not run without /mnt/cirrus being mounted
  systemd.services.slurmd = {
    requires = ["mnt-cirrus.mount"];
    after = ["mnt-cirrus.mount"];
    partOf = ["mnt-cirrus.mount"];
  };

  networking.firewall.allowedTCPPorts = [6818];
}
