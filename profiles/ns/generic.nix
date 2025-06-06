{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dig
    dogdns
    git
    bind
    #the following are needed to build the dns packaged
    pull-repo
    gnumake
    ipv6calc
    gnum4
  ];
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
  services.bind = {
    cacheNetworks = [
      "127.0.0.1"
      "193.136.164.0/24" # a nossa gama 164
      "193.136.154.0/24" # a nossa gama 154
      "2001:690:2100:80::/58" # toda a RNL via IPv6
      "192.168.0.0/16" # IPs privados internos da RNL
      "10.16.80.0/20" # IPs privados IST da RNL
    ];
    extraOptions = ''
      recursion yes;
      max-cache-size 768M;'';
    extraConfig = '''';
    forwarders = [
      "2001:690:a80:4001::200" # estes dois são ns02.fccn.pt
      "193.136.2.228"
    ];
  };
  age.secrets."root-at-ns-ssh.key" = {
    file = ../../secrets/root-at-ns-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };
}
