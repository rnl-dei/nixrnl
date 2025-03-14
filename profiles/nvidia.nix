{ pkgs, ... }:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # It is suggested to use the open source kernel modules on Turing or
  # later GPUs (RTX series, GTX 16xx), and the closed source modules otherwise.
  hardware.nvidia.open = true;
  hardware.nvidia-container-toolkit.enable = true;

  # Enable cuda support
  # nixpkgs.config.cudaSupport = true; is not viable, tries to recompile the universe and fails.
  # Use the -bin version of packages which require cuda support instead.
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvrtc
  ];

  environment.variables."CUDA_PATH" = "${pkgs.cudaPackages.cudatoolkit}";
  environment.variables."LD_LIBRARY_PATH" = "${pkgs.cudaPackages.cudatoolkit}/lib";
  environment.variables."EXTRA_LDFLAGS" = "-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib";

  # caixinha penso que se mudares isto para ficar tipo "CFLAGS" só isto funciona
  environment.variables."EXTRA_CPPFLAGS" =
    "-I/usr/include -I${pkgs.cudaPackages.cudatoolkit}/include";

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
    wantedBy = [ "multi-user.target" ];
  };
}
