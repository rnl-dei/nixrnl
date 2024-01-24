{...}: {
  rnl.ftp-server.mirrors.gentoo-portage = {
    source="rsync://masterportage.gentoo.org/gentoo-portage";
    target="/mnt/data/ftp/pub/gentoo-portage";
    timer="*-*-* 0..2,4..23:10,40:00"; # Every 30 minutes
  };
}
