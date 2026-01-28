{ config, lib, ... }:
{
  environment.etc."ssh/authorized_keys.d/root" = {
    text = lib.strings.concatStrings config.users.users.root.openssh.authorizedKeys.keys;
  };
}
