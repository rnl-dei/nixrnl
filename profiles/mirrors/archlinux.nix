{ ... }:
{
  rnl.ftp-server.mirrors.archlinux = {
    source = "rsync://rsync.archlinux.org/ftp_tier1/";
    target.path = "/mnt/data/ftp/pub/archlinux";
    timer = "*-*-* 0...23:30:00"; # Every day at 30 minutes past the hour
    extraArgs = [ "--max-delete=7000" ];
  };
}
