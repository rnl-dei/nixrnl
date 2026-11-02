{ ... }:
{
  rnl.ftp-server.mirrors.ubuntu-releases = {
    source = "rsync://rsync.releases.ubuntu.com/releases/";
    target.path = "/mnt/data/ftp/pub/ubuntu/releases";
    timer = "*-*-* 2:00:00"; # Every day at 2:00am
  };
}
