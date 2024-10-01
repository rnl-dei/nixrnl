{...}: {
  aliases = {
    "alpha".extraModules = [
      {
        rnl.monitoring.snmp = true;
      }
    ];
    "omega".extraModules = [
      {
        rnl.monitoring.snmp = true;
      }
    ];

    # Name of the chassis cluster
    "zeus".extraModules = [{}];
  };
}
