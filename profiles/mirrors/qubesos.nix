{ ... }:
{
  rnl.ftp-server.mirrors.qubesos = {
    source = "rsync://rsync.qubes-os.org/qubes-mirror/";
    target.path = "/mnt/data/ftp/pub/qubesos";
    timer = "*-*-* 23:00:00"; # Every day at 23:00
  };
}
