{...}: {
  system.stateVersion = "";
  rnl.labels.os = "windows";

  services.prometheus.exporters.node.port = 9182;
}
