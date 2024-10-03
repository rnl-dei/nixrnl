{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./afs.nix
    ./ldap.nix
    ./kerberos.nix
  ];

  services.sssd = {
    enable = true;
    config = ''
      [sssd]
      config_file_version = 2
      services = nss, pam
      domains = DEFAULT

      [nss]
      override_shell = ${pkgs.bashInteractive}/bin/bash

      [domain/DEFAULT]
      # debug_level = 5 # Uncomment for debugging
      id_provider = ldap
      ldap_uri = ${config.users.ldap.server}
      ldap_search_base = ${config.users.ldap.base}

      ldap_user_fullname = displayName

      auth_provider = krb5
      chpass_provider = krb5
      krb5_realm = ${config.security.krb5.settings.libdefaults.default_realm}
      krb5_server = ${config.security.krb5.settings.realms.${config.security.krb5.settings.libdefaults.default_realm}.default_domain}
    '';
  };

  # Setup PAM login
  security.pam.services.login.startSession = true;
  security.pam.krb5.enable = false; # Use SSSD instead

  # Get AFS ticket from Kerberos on login and ssh
  security.pam.services.login.text = lib.mkDefault (lib.mkOrder 1500 ''
    session optional ${pkgs.pam_afs_session}/lib/security/pam_afs_session.so program=${config.services.openafsClient.packages.programs}/bin/aklog nopag
    session optional pam_exec.so ${pkgs.subidappend}/bin/subidappend
  '');
  security.pam.services.sshd.text = lib.mkDefault (lib.mkOrder 1500 ''
    session optional ${pkgs.pam_afs_session}/lib/security/pam_afs_session.so program=${config.services.openafsClient.packages.programs}/bin/aklog nopag
    session optional pam_exec.so ${pkgs.subidappend}/bin/subidappend
  '');

  # Allow SSH using istID
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Enable Kerberos login to Sigma
  programs.ssh.extraConfig = ''
    # Enable kerberos SSH authentication into sigma
    Host *.tecnico.ulisboa.pt *.ist.utl.pt
      GSSAPIAuthentication yes
      GSSAPIDelegateCredentials yes
  '';

  # Ensure users can't overload the system
  # These settings constrain resources consumed by *all* users, globally.
  systemd.slices."user".sliceConfig = {
    MemoryMax = "95%"; # 2GB * 95% ≃ 1.9GB

    # Page cache management is dumb and reclamation is not automatic when memory runs out
    # MemoryHigh is a soft-limit that triggers aggressive memory reclamation, preventing OOM kills when the page cache starts to grow
    # This prevents something like downloading a large file to a FS with a large write cache from being OOM-killed
    MemoryHigh = "94%"; # set to just under MemoryMax

    # Note: CPUQuota is not set here because percentages are relative to one CPU, not the total amount of resources
    # Also, DO NOT SET CPUQUOTA WITHOUT TESTING IT. It made borg slow down to unacceptable levels.
    # See https://papyrus.rnl.tecnico.ulisboa.pt/rnl/pl/kuen4nzcd3dsx8f1tqugsg5fba for context.

    CPUWeight = 90; # default is 100
    IOWeight = 90; # default is 100
  };

  # Prevent fork bombs
  systemd.slices."user-" = {
    sliceConfig = {
      # @ist189409's computer had ~1600 tasks in /user.slice
      # This ought to be enough to accommodate any not-too-unreasonable workload, while stopping fork bombs.
      TasksMax = lib.mkDefault 4096;
    };

    # user-.slice does not exist, the settings must be stored under user-.slice.d/overrides.conf (a "drop-in" file) for this to work.
    overrideStrategy = "asDropin";
  };

  # The root user should be able to perform maintenance:
  # we override the previous defaults with higher limits for this.
  # Note that this only applies to processes created under login shells (through SSH, serial console, TTYs, etc.)
  systemd.slices."user-0".sliceConfig = {
    MemoryHigh = "infinity";
    MemoryMax = "infinity";

    # give more priority to root CPU/IO
    CPUWeight = 110; # default is 100
    IOWeight = 110; # default is 100
  };

  # Use "classic ptrace permissions", that allows processes to ptrace any others running
  # under the same UID (as long as they are dumpable).
  # See https://www.kernel.org/doc/Documentation/security/Yama.txt for more information.
  #
  # The default is "1", which only allows ptrace-ing when the tracer and tracee processes
  # are parent and child. This is good for security but cumbersome in a multi-user machine
  # for developers who may only remember they only want to trace a program after it starts
  # and encounters a (potentially hard to reproduce) bug.
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;
}
