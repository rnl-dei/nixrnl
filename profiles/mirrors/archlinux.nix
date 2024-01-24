{...}: {
  rnl.ftp-server.mirrors.archlinux = {
    source = "rsync://rsync.archlinux.org/ftp_tier1/";
    target = "/mnt/data/ftp/pub/archlinux";
    timer = "*-*-* 0..2,4..23:50:00"; # Every day at 50 minutes past the hour, except at 3am
    extraArgs = [ "--max-delete=7000" ];
  };
}
