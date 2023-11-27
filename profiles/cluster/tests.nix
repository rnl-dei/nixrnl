{...}: {
  # Use labX for tests
  services.slurm = {
    controlMachine = "borg2";
    clusterName = "RNL-Cluster-Tests";
    nodeName = [
      "labXp[1-5] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=labX"
    ];
    partitionName = ["compute Nodes=labXp[1-5] Default=YES MaxTime=20160 DefaultTime=60 State=UP"];
  };
}
