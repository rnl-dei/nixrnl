{ ... }:
{
  rnl.ftp-server.mirrors.opensuse = {
    source = "rsync://stage.opensuse.org/opensuse-full-with-factory/opensuse/";
    target.path = "/mnt/data/ftp/pub/opensuse";
    timer = "*-*-* 5..23/6:00:00"; # Every 6 hours
  };
}
