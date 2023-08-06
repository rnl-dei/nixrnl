{
  config,
  lib,
  nixosConfigurations,
  pkgs,
  ...
}: let
  getIsoPathFromHost = host: let iso = host.config.system.build.isoImage; in iso + "/iso/" + iso.isoName;
in {
  "nixos-live" = getIsoPathFromHost nixosConfigurations.live;

  "ubuntu-23.04" = pkgs.fetchurl {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/pub/ubuntu/releases/23.04/ubuntu-23.04-live-server-amd64.iso";
    sha256 = "0srl1p42p65yl4c3isn9y2zb6968r4zqlf34b5kdkmx6jj2a9kf7";
  };
  "windows-server-2019" = pkgs.fetchurl {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/pub/ubuntu/releases/23.04/ubuntu-23.04-live-server-amd64.iso";
    sha256 = "0srl1p42p65yl4c3isn9y2zb6968r4zqlf34b5kdkmx6jj2a9kf7";
  };
  "virtio-win" = pkgs.fetchurl {
    url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso";
    sha256 = "1q5vrcd70kya4nhlbpxmj7mwmwra1hm3x7w8rzkawpk06kg0v2n8";
  };
}
