{...}: {
  rnl.ftp-server.mirrors.ubuntu-releases = {
    #source = "rsync://rsync.releases.ubuntu.com/releases";
    source = "rsync://ftp.rnl.tecnico.ulisboa.pt/pub/ubuntu/releases";
    target = "/mnt/data/ftp/pub/ubuntu/releases";
    timer = "*-*-* 2:20:00"; # Every day at 2:20am
  };
}
