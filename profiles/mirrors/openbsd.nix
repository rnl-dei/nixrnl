{...}:{
  rnl.ftp-server.mirrors.openbsd = {
  source = "rsync://ftp.fau.de/openbsd/";
  target = "/mnt/storage/pub/OpenBSD";
  extraArgs = [ "--timeout=6000" ];

    source = "rsync://mirror.zorinos.com/isos";
    target = "/mnt/data/ftp/pub/zorinos";
    timer = "*-*-* 9:00:00"; # Every day at 9am
  };
}
