{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kea ];
  # Configure Hashicorp Vault
  services.kea.dhcp4 = {
    enable = true;
  };
}
