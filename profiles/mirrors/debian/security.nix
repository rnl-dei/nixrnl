{ pkgs, ... }:
{
  rnl.ftp-server.mirrors.debian-security = rec {
    source = "rsync://rsync.uni-bayreuth.de/debian-security";
    target.path = "/mnt/data/ftp/pub/debian-security";
    timer = "*-*-* 23:00:00"; # Every day at 23:00
    script = "${pkgs.archvsync}/bin/ftpsync";
    extraServiceConfig.environment = {
      RSYNC_EXTRA = "-h";
      RSYNC_SOURCE = source;
      TO = target.path;
    };
  };
}
