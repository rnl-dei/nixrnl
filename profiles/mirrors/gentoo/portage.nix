{ ... }:
{
  rnl.ftp-server.mirrors.gentoo-portage = {
    #source = "rsync://masterportage.gentoo.org/gentoo-portage";
    source = "rsync://193.136.164.6/pub/gentoo/gentoo-portage";
    target = "/mnt/data/ftp/pub/gentoo/gentoo-portage";
    timer = "*-*-* 0/4:00:00"; # every 4 hours
  };
}
