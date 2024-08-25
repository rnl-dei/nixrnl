{...}: {
  imports = [./common.nix];

  services.slurm.client.enable = true;

  systemd.services.slurmd = {
    # Ensure slurmd does not run without /mnt/cirrus being mounted
    requires = ["mnt-cirrus.mount"];
    after = ["mnt-cirrus.mount"];
    partOf = ["mnt-cirrus.mount"];

    serviceConfig = {
      # Auto-restart slurmd to sidestep temporary issues
      Restart = "on-failure";
      # Minimum time to wait between restarts
      RestartSec = 5;

      # Use exponential back-off when restarting multiple times.
      # NOTE: this does not seem to reset on its own. Keep maximum delay within reason.
      # Maximum time to wait between restarts
      RestartMaxDelaySec = "1h";
      # Steps of exponential growth to reach max restart delay from min restart delay
      RestartSteps = 10;
    };
  };

  networking.firewall.allowedTCPPorts = [6818];
}
