{...}: {
  rnl.ftp-server.mirrors.opensuse = {
    source = "rsync://stage.opensuse.org/opensuse-full/opensuse/";
    target = "/mnt/data/ftp/pub/opensuse";
    timer = "*-*-* 4..23/6:20:00"; # Every 6 hours between 4am and 11pm
  };
}
