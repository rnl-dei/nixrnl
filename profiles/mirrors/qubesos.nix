{...}: {
  rnl.ftp-server.mirrors.qubesos = {
    #source = "rsync://rsync.qubes-os.org/qubes-mirror";
    source = "rsync://ftp.rnl.tecnico.ulisboa.pt/pub/qubesos";
    target = "/mnt/data/ftp/pub/qubesos";
    timer = "*-*-* 15:20:00"; # Every day at 15:20
  };
}
