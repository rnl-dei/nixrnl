{...}: {
  rnl.ftp-server.mirrors.gentoo-portage = {
    #source = "rsync://masterportage.gentoo.org/gentoo-portage";
    source = "rsync://193.136.164.6/pub/gentoo/gentoo-portage";
    target = "/mnt/data/ftp/pub/gentoo/gentoo-portage";
    timer = "*-*-* 0..2,4..23:10,40:00"; # Every 30 minutes
  };
}
