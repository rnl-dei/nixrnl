{ ... }:
{
  rnl.ftp-server.mirrors.linuxmint-packages = {
    source = "rsync://rsync-packages.linuxmint.com/packages/";
    target.path = "/mnt/data/ftp/pub/linuxmint-packages";
    timer = "*-*-* 8,20:00:00"; # Every day at 8:00 and 20:00
    extraArgs = [
      "--exclude=\"*.php\""
      "--delete-excluded"
    ];
  };
}
