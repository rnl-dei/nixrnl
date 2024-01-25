{...}: {
  rnl.ftp-server.mirrors.cygwin = {
    #source = "rsync://cygwin.com/cygwin-ftp";
    source = "rsync://ftp.rnl.tecnico.ulisboa.pt/pub/cygwin";
    target = "/mnt/data/ftp/pub/cygwin";
    timer = "*-*-* 5,17:00:00"; # Every day at 5am and 5pm
  };
}
