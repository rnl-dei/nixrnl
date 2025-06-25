{ lib, ... }:
{
  imports = [ ./common.nix ];

  services.slurm.client.enable = true;

  systemd.services.slurmd = {
    # Ensure slurmd does not run without /mnt/cirrus being mounted
    requires = [ "mnt-cirrus.mount" ];
    after = [ "mnt-cirrus.mount" ];
    partOf = [ "mnt-cirrus.mount" ];

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

  networking.firewall.allowedTCPPorts = [ 6818 ];

  # Slurm has been acting up, store more logs
  # TODO: go back to the default (10% max / 15% keep free but capped to 4GB)
  services.journald.extraConfig = ''
    [Journal]
    SystemMaxUse=50G
    SystemKeepFree=80G
  '';
  systemd.services.deal-with-slurmd-boot = {
    description = "Restarts slurmd until a node is ready.";
    wantedBy = [ "multi-user.target" ];
    after = [ "slurmd.service" ];
    environment = {
      PATH = lib.mkForce "/run/current-system/sw/bin/:$PATH";
    };
    # If multiple attempts of the service are needed, slurmd should only make 1 reservation because of the fixed name
    script = ''
      hostname=$(hostname)
      reservation_name="$(hostname)-boot"
      scontrol create reservation ReservationName=$reservation_name user=root starttime=now \
        duration=infinite flags=maint nodes=$hostname || :
      success=1
        for i in {1..100}; do
          srun --reservation=$reservation_name -w $hostname hostname || :
          if [ $? -eq 0 ]; then
            scontrol delete ReservationName=$reservation_name
            success=0
            break
          fi
          systemctl restart slurmd
          sleep $i
      done
      if [ $success -eq 0 ]; then
        echo "Successfully started slurmd after $i tries."
      else
        echo "Failed to start slurmd."
        return 1
      fi
    '';
  };
}
