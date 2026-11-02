{ ... }:
{
  rnl.ftp-server.mirrors.mxlinux-packages = {
    source = "rsync://ftp.cica.es/MX-Packages/"; # Spanish mirror, probs fine
    target.path = "/mnt/data/ftp/pub/mxlinux-packages";
    timer = "*-*-* 10,22:00:00"; # Twice a day, at 10:00 and 22:00
  };
}
