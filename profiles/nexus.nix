{lib, ...}: {
  imports = [./software/shell.nix];

  services.keepalived = {
    enable = lib.mkDefault true;
    vrrpInstances.nexusIP4 = {
      virtualRouterId = 129;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "193.136.164.129/26";}]; # nexus IPv4
    };
    vrrpInstances.nexusIP6 = {
      virtualRouterId = 129;
      interface = lib.mkDefault "enp1s0";
      virtualIps = [{addr = "2001:690:2100:83::129/64";}]; # nexus IPv6
    };
  };

  # Allow users to access the machine from outside the network
  networking.firewall = let
    portRanges = {
      from = 1024;
      to = 65535;
    };
  in {
    allowedTCPPortRanges = [ portRanges ];
    allowedUDPPortRanges = [ portRanges ];
  };

  users.motd = ''

    ################################################################################

      [1;37mWelcome to Nexus[0m
      https://rnl.tecnico.ulisboa.pt/servicos/unix_shell

      Be aware that [1;31mwill be terminated without previous advertisement,
      any process that is consuming 100% of CPU[0m for an unreasonable
      amount of time.

    ################################################################################

  '';

  # This machine sees more users, and is low-spec. Must tighten resource limits.
  # Overrides limits from profile/ist-shell
  # TODO: move to somewhere where it can be shared with borg(cluster server) and other heavily shared machines.
  systemd.slices."user-".sliceConfig = {
    MemoryMax = "10%"; # 8GB * 10% ≃ 800MB

    # Page cache management is dumb and reclamation is not automatic when memory runs out
    # MemoryHigh is a soft-limit that triggers agressive memory reclamation, preventing OOM kills when the page cache starts to grow
    # This prevents something like downloading a large file to a FS with a large write cache from being OOM-killed
    MemoryHigh = "9%"; # set to just under MemoryMax

    # Prevent fork-bombs
    TasksMax = 1024; # 4096 is too much in a low-spec machine
    # If the value is set too high, OOM killer will kick in first and leave the machine sluggish (not impossible to recover, but still annoying).
  };
}
