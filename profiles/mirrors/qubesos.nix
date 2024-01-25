{...}: {
  rnl.ftp-server.mirrors.qubesos = {
    #source = "rsync://rsync.qubes-os.org/qubes-mirror/";
    source = "rsync://193.136.164.6/pub/qubesos/";
    target = "/mnt/data/ftp/pub/qubesos";
    timer = "*-*-* 15:20:00"; # Every day at 15:20
  };
}
