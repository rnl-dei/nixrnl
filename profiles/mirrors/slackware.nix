{...}: let
  exclude = builtins.toFile "slackware-exclude" ''
    /slackware-1.*
    /slackware-2.*
    /slackware-3.*
    /slackware-4.*
    /slackware-7.*
    /slackware-8.*
    /slackware-9.*
    /slackware-10.*
    /slackware-11.*
    /slackware-12.*
    /slackware-13.*
    /slackware-iso/slackware-13.*
    /slackware-iso/slackware64-13.*
    /slackware-pre-1.0-beta
  '';
in {
  rnl.ftp-server.mirrors.slackware = {
    source = "rsync://slackware.uk/slackware/";
    target = "/mnt/data/ftp/pub/slackware";
    extraArgs = ["--exclude-from ${exclude}" "--delete-excluded"];
    timer = "*-*-* 0..23/6:00:00"; # Every day at 3am
  };
}
