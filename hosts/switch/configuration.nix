{...}: {
  aliases = {
    #
    # Inf1, Floor 01, Rack A1
    #
    "sw-lab0-rede-core1".extraModules = [
      {
        rnl.labels.location = "inf1-p01-a1";
      }
    ];
    "sw-lab0-rede-core2".extraModules = [
      {
        rnl.labels.location = "inf1-p01-a1";
      }
    ];

    #
    # Inf1, Floor 01, Rack A2
    #
    "sw-lab0-srv1-core".extraModules = [
      {
        rnl.labels.location = "inf1-p01-a2";
      }
    ];
    "sw-lab0-srv1-labs".extraModules = [
      {
        rnl.labels.location = "inf1-p01-a2";
      }
    ];

    #
    # Inf1, Floor 01, Rack A3
    #
    "sw-lab0-srv2".extraModules = [
      {
        rnl.labels.location = "inf1-p01-a3";
      }
    ];

    #
    # Inf1, Floor 2, Rack C
    #
    "sw-inf1-p2-c1-1".extraModules = [
      {
        rnl.labels.location = "inf1-p2-c";
      }
    ];
    "sw-inf1-p2-c1-2".extraModules = [
      {
        rnl.labels.location = "inf1-p2-c";
      }
    ];
  };
}
