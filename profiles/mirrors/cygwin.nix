{ ... }:
{
  rnl.ftp-server.mirrors.cygwin = {
    #source = "rsync://cygwin.com/cygwin-ftp/";
    source = "rsync://193.136.164.6/pub/cygwin/";
    target.path = "/mnt/data/ftp/pub/cygwin";
    timer = "*-*-* 5,17:00:00"; # Every day at 5am and 5pm
  };
}
