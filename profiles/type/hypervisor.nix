{...}: {
  imports = [./physical.nix];

  # Overall hosts are Intel but some are AMD
  boot.kernelModules = ["kvm-intel" "kvm-amd"];

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    parallelShutdown = 5; # Arbitrary number of machines
  };

  hardware.ksm.enable = true;
  services.irqbalance.enable = true;

  rnl.virtualisation.enable = true;

  rnl.labels.type = "hypervisor";

  environment.shellAliases = {
    virsh-shutdown-all = "virsh list --name | xargs -I{} virsh shutdown {}";
  };
}
