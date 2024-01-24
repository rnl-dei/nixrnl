{...}: {
  rnl.ftp-server.mirrors.gentoo-distfiles = {
    source="gentoo@masterdistfiles.gentoo.org::gentoo";
    target="/mnt/data/ftp/pub/gentoo-distfiles";
    timer="*-*-* 0..23:00:00"; # Every 30 minutes
    extraArgs = [
    "-D"
    "--password-file=" # FIXME: Add password file
    "--exclude THIS-FILE-SHOULD-NOT-BE-PUBLIC.txt" "--delete-excluded"];
  };
}
