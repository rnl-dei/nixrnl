{
  config,
  pkgs,
  ...
}: {
  virtualisation.containers.cdi.dynamic.nvidia.enable = true;

  # Make sure opengl is enabled
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Tell Xorg to use the nvidia driver
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed for most wayland compositors
    modesetting.enable = true;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable cuda support
  # nixpkgs.config.cudaSupport = true; is not viable, tries to recompile the universe and fails.
  # Use the -bin version of packages which require cuda support instead.
  environment.systemPackages = with pkgs; [cudatoolkit];
  environment.variables."CUDA_PATH" = "${pkgs.cudatoolkit}";

  # Slurm needs to know how to detect GPUs
  # TODO: consider using oneapi for all nodes, as it should detect *any* GPU
  services.slurm.extraConfigPaths = [
    (pkgs.writeTextDir "gres.conf" ''
      # Automatically detect NVIDIA GPUs with NVIDIA Management Library
      AutoDetect=nvml
    '')
  ];

  systemd.services."nvidia_gpu_exporter" = {
    description = "NVIDIA GPU Exporter";
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.prometheusExporters.nvidia}/bin/nvidia_gpu_exporter";
      SyslogIdentifier = "nvidia_gpu_exporter";
      Restart = "always";
      RestartSec = "1";
    };
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
  };
}
