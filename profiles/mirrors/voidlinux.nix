{...}: {
  rnl.ftp-server.mirrors.voidlinux = {
    source = "rsync://repo-sync.voidlinux.org/voidlinux/";
    target = "/mnt/data/ftp/pub/voidlinux";
    timer = "*-*-* 14:15:00"; # Every day at 14:15
  };
}
