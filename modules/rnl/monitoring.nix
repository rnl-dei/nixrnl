{
  config,
  lib,
  ...
}:
with lib; {
  options.rnl.monitoring = {
    ping = mkOption {
      type = types.bool;
      description = "Check if host answer to ping in IPv4";
      default = true;
    };
    ping6 = mkOption {
      type = types.bool;
      description = "Check if host answer to ping in IPv6";
      default = config.rnl.monitoring.ping && config.networking.enableIPv6;
    };
    snmp = mkOption {
      type = types.bool;
      description = "Get SNMP information";
      default = false;
    };
    amt = mkOption {
      type = types.bool;
      description = "Check if AMT is reachable";
      default = false;
    };
  };
}
