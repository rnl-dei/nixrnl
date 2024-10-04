{ nixosConfigurations, ... }:
let
  build = nixosConfigurations.live-netboot-dhcp.config.system.build;
in
{
  services.pixiecore = {
    enable = true;
    openFirewall = true;
    dhcpNoBind = true; # Use existing DHCP server.

    mode = "boot";
    kernel = "${build.kernel}/bzImage";
    initrd = "${build.netbootRamdisk}/initrd";
    cmdLine = "init=${build.toplevel}/init loglevel=4";
    debug = true;
  };

  # Enable this to fix this issue:
  # https://github.com/NixOS/nixpkgs/issues/252116
  networking.firewall.allowedUDPPorts = [ 4011 ];
}
