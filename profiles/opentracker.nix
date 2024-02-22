{...}: {
  services.opentracker = {
    enable = true;
    extraOptions = "-P 31000"; # Run on port 31000/udp
  };

  networking.firewall.allowedUDPPorts = [31000];
}
