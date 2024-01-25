{
  config,
  pkgs,
  ...
}: let
  script = ''
    fatal() {
      echo "$1"
      exit 1
    }

    warn() {
      echo "$1"
    }

    RSYNCSOURCE=${config.rnl.ftp-server.mirrors.ubuntu-archive.source}

    # Define where you want the mirror-data to be on your mirror
    BASEDIR=${config.rnl.ftp-server.mirrors.ubuntu-archive.target}

    if [ ! -d $BASEDIR ]; then
      warn "$BASEDIR does not exist yet, trying to create it..."
      mkdir -p $BASEDIR || fatal "Creation of $BASEDIR failed."
    fi

    ${pkgs.rsync}/bin/rsync --recursive --times --links --safe-links --hard-links \
      --stats \
      --exclude "Packages*" --exclude "Sources*" \
      --exclude "Release*" --exclude "InRelease" \
      $RSYNCSOURCE $BASEDIR || fatal "First stage of sync failed."

    ${pkgs.rsync}/bin/rsync --recursive --times --links --safe-links --hard-links \
      --stats --delete --delete-after \
      $RSYNCSOURCE $BASEDIR || fatal "Second stage of sync failed."

    ${pkgs.coreutils}/bin/date -u > $BASEDIR/project/trace/$(${pkgs.hostname}/bin/hostname -f)
  '';
in {
  rnl.ftp-server.mirrors.ubuntu-archive = {
    #source = "rsync://archive.ubuntu.com/ubuntu";
    source = "rsync://193.136.164.6/pub/ubuntu/archive";
    target = "/mnt/data/ftp/pub/ubuntu/archive";
    timer = "*-*-* 5..23/6:20:00"; # Every day at 20 minutes past the hour, 6 in 6 hours
    script = script;
  };
}
