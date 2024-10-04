{ lib, profiles, ... }:
{
  imports = with profiles; [
    core.rnl
    filesystems.unknown
    os.unknown
    type.switch
  ];

  # Disable ping IPv6 monitoring
  rnl.monitoring.ping6 = false;

  # Enable SNMP monitoring by default
  rnl.monitoring.snmp = lib.mkDefault true;
}
