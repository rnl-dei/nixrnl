{
  lib,
  config,
  ...
}: {
  services.transmission = {
    enable = true;
    openFirewall = true;
    openRPCPort = true;
    settings = {
      # rpc-username and rpc-password
      # Must be configured in the services.transmission.credentialsFile
      rpc-authentication-required = lib.mkDefault true;
      rpc-host-whitelist = lib.mkDefault "*.${config.rnl.domain}";
      rpc-whitelist-enabled = lib.mkDefault false;
      rpc-bind-address = lib.mkDefault "*";
      rpc-port = lib.mkDefault 9091;
      watch-dir-enabled = true;
    };
  };
}
