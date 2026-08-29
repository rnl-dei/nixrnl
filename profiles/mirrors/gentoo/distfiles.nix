{ config, ... }:
{
  rnl.ftp-server.mirrors.gentoo-distfiles = {
    source = "gentoo@masterdistfiles.gentoo.org::gentoo";
    target.path = "/mnt/data/ftp/pub/gentoo/gentoo-distfiles";
    timer = "*-*-* 0/4:00:00"; # every 4 hours
    extraArgs = [
      "-D"
      "--password-file=${config.age.secrets."gentoo-distfiles-ssh.key".path}"
      "--exclude THIS-FILE-SHOULD-NOT-BE-PUBLIC.txt"
      "--delete-excluded"
    ];
  };

  age.secrets."gentoo-distfiles-ssh.key" = {
    # FIXME: update the key management
    file = ../../../secrets/ftp-gentoo-auth.age;
    owner = config.rnl.ftp-server.mirrors.gentoo-distfiles.user;
    group = config.rnl.ftp-server.mirrors.gentoo-distfiles.group;
  };
}
