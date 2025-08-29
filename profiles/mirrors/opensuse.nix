{ ... }:
{
  rnl.ftp-server.mirrors.opensuse = {
    #source = "rsync://stage.opensuse.org/opensuse-full-with-factory/opensuse/";
    source = "rsync://193.136.164.6/pub/opensuse/";
    target.path = "/mnt/data/ftp/pub/opensuse";
    timer = "*-*-* 4..23/6:20:00"; # Every 6 hours between 4am and 11pm
  };
}
