{ ... }:
{
  rnl.ftp-server.mirrors.videolan = {
    source = "rsync://rsync.videolan.org/videolan-ftp/";
    target.path = "/mnt/data/ftp/pub/videolan";
    timer = "*-*-* *:30:00"; # Every day at 30 minutes past the hour
  };
}
