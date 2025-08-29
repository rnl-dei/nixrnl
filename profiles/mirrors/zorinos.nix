{ ... }:
{
  rnl.ftp-server.mirrors.zorinos = {
    source = "rsync://mirror.zorinos.com/isos/";
    target.path = "/mnt/data/ftp/pub/zorinos";
    timer = "*-*-* 9:00:00"; # Every day at 9am
  };
}
