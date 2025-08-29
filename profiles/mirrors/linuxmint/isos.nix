{ ... }:
{
  rnl.ftp-server.mirrors.linuxmint-isos = {
    source = "rsync://pub.linuxmint.com/pub/";
    target.path = "/mnt/data/ftp/pub/linuxmint";
    timer = "*-*-* 20:20:00"; # Every day at 20:20
  };
}
