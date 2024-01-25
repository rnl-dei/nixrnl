{...}: {
  rnl.ftp-server.mirrors.openbsd = {
    source = "rsync://ftp.fau.de/openbsd/";
    target = "/mnt/data/ftp/pub/OpenBSD";
    extraArgs = ["--timeout=6000"];
    timer = "*-*-* 9:00:00"; # Every day at 9am
  };
}
