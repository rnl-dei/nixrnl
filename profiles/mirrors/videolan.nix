{ ... }:
{
  rnl.ftp-server.mirrors.videolan = {
    source = "rsync://rsync.videolan.org/videolan-ftp/";
    target.path = "/mnt/data/ftp/pub/videolan";
    timer = "*-*-* 3:00:00"; # Every day at 3 am
  };
}
