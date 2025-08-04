{
  pkgs,
  lib,
  ...
}:
{
  rnl.ftp-server.mirrors.debian-cd = rec {
    source = "rsync://ftp.rnl.tecnico.ulisboa.pt/pub/debian-cd";
    target = "/mnt/data/ftp/pub/debian-cd";
    timer = "*-*-* 21:00:00"; # Every day at 21:00
    command = "${pkgs.archvsync}/bin/ftpsync";
    args = lib.mkForce [ ];
    # FIXME: exclude stupidly big files for now
    extraServiceConfig.environment = {
      RSYNC_SOURCE = source;
      TO = target;
      # RSYNC_EXTRA = config.rnl.ftp-server.mirror.debian-cd.args;
      ARCH_INCLUDE = "arm";
      # ARCH_EXCLUDE = "source";
      RSYNC_EXTRA = lib.concatStrings (
        lib.strings.intersperse " " [
          "--include='*netinst*.iso'"
          #"--include='i386/**.iso'"
          # "--include='amd64/**.iso'"
          #"--exclude='*.iso'"
          #"--exclude='source/'"
        ]
      );
    };
  };
}
