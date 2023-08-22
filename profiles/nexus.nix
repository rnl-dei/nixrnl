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

  users.motd = ''

    ################################################################################

      [1;37mWelcome to Nexus[0m
      https://rnl.tecnico.ulisboa.pt/servicos/unix_shell

      Be aware that [1;31mwill be terminated without previous advertisement,
      any process that is consuming 100% of CPU[0m for an unreasonable
      amount of time.

    ################################################################################

  '';
}
