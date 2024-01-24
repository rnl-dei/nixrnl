{...}: {
  rnl.ftp-server.mirrors.ubuntu-archive = {
    # FIXME: Use custom script
    source = "rsync://archive.ubuntu.com/ubuntu";
    target = "/mnt/data/ftp/pub/ubuntu-archive";
    timer = "*-*-* 5..23/6:20:00"; # Every day at 20 minutes past the hour, 6 in 6 hours
  };
}
