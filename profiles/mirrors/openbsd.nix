{ ... }:
{
  rnl.ftp-server.mirrors.openbsd = {
    source = "rsync://ftp.fau.de/openbsd/";
    target.path = "/mnt/data/ftp/pub/OpenBSD";
    extraArgs = [ "--timeout=6000" ];
    timer = "*-*-* 6:00:00"; # Every day at 6am
  };
}
