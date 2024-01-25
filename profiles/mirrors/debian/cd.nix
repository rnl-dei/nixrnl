{pkgs, ...}: {
  rnl.ftp-server.mirrors.debian-cd = rec {
    source = "rsync://rsync.uni-bayreuth.de/debian-cd";
    target = "/mnt/data/ftp/pub/debian-cd";
    timer = "*-*-* 21:00:00"; # Every day at 21:00
    script = "${pkgs.archvsync}/bin/ftpsync";
    extraServiceConfig.environment = {
      RSYNC_SOURCE = source;
      TO = target;
    };
  };
}
