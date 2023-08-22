{...}: {
  imports = [./common.nix];

  services.slurm.client.enable = true;

  networking.firewall.allowedTCPPorts = [6818];
}
