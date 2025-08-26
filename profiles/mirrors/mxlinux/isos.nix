{ ... }:
{
  rnl.ftp-server.mirrors.mxlinux-isos = {
    source = "rsync://rsync-mxlinux.org/"; # NOTE: Confirm working remote
    target = "/mnt/data/ftp/pub/mxlinux-isos";
    timer = "*-*-* 10,22:00:00"; # Twice a day, at 10:00 and 22:00
  };
}
