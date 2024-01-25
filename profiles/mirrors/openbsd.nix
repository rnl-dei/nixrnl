{...}: {
  rnl.ftp-server.mirrors.openbsd = {
    #source = "rsync://ftp.fau.de/openbsd/";
    source = "rsync://193.136.164.6/pub/OpenBSD/";
    target = "/mnt/data/ftp/pub/OpenBSD";
    extraArgs = ["--timeout=6000"];
    timer = "*-*-* 9:00:00"; # Every day at 9am
  };
}
