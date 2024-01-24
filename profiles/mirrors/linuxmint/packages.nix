{...}: {
  rnl.ftp-server.mirrors.linuxmint-packages = {
    source = "rsync://rsync-packages.linuxmint.com/packages/";
    target="/mnt/data/ftp/pub/linuxmint-packages";
    timer="*-*-* 5,17:20:00"; # Every day at 5:20 and 17:20
    extraArgs = [ "--exclude=\"*.php\"" "--delete-excluded" ];
  };
}
