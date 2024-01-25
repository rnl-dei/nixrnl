{config, ...}: {
  rnl.ftp-server.mirrors.gentoo-distfiles = {
    #source = "gentoo@masterdistfiles.gentoo.org::gentoo";
    source = "rsync://193.136.164.6/pub/gentoo/gentoo-distfiles/";
    target = "/mnt/data/ftp/pub/gentoo/gentoo-distfiles";
    timer = "*-*-* 0..23:00:00"; # Every 30 minutes
    extraArgs = [
      "-D"
      # "--password-file=${config.age.secrets."gentoo-distfiles-ssh.key".path}" # FIXME: Uncomment when moving to production
      "--exclude THIS-FILE-SHOULD-NOT-BE-PUBLIC.txt"
      "--delete-excluded"
    ];
  };

  age.secrets."gentoo-distfiles-ssh.key" = {
    file = ../../../secrets/gentoo-distfiles-ssh-key.age;
    owner = config.rnl.ftp-server.mirrors.gentoo-distfiles.user;
    group = config.rnl.ftp-server.mirrors.gentoo-distfiles.group;
  };
}
