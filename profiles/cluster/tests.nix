{...}: {
  # Use lab0 for tests
  services.slurm = {
    controlMachine = "borg2";
    clusterName = "RNL-Cluster-Tests";
    nodeName = [
      "lab0p[1-4] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 RealMemory=10240 Features=lab0"
    ];
    partitionName = ["compute Nodes=lab0p[1-4] Default=YES MaxTime=20160 DefaultTime=60 State=UP"];
  };
}
