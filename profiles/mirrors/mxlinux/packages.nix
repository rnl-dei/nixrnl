{ ... }:
{
  rnl.ftp-server.mirrors.mxlinux-packages = {
    source = "rsync://ftp.cica.es/MX-Packages/"; # Spanish mirror, probs fine
    target = "/mnt/data/ftp/pub/mxlinux-packages";
    timer = "*-*-* 9,21:00:00"; # Twice a day, at 9:00 and 21:00
  };
}
