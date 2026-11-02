{ pkgs, ... }:
{
  rnl.ftp-server.mirrors.debian = rec {
    source = "rsync://rsync.uni-bayreuth.de/debian";
    target.path = "/mnt/data/ftp/pub/debian";
    timer = "*-*-* 1..24/6:00:00"; # Every 6 hours
    script = "${pkgs.archvsync}/bin/ftpsync";
    extraServiceConfig.environment = {
      RSYNC_SOURCE = source;
      TO = target.path;
    };
  };
}
