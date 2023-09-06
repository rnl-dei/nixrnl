{
  pkgs,
  lib,
  config,
  ...
}: {
  # Setup AFS
  services.openafsClient = {
    enable = true;
    mountPoint = "/afs";
    cellName = "ist.utl.pt";
    cellServDB = [
      {
        ip = "193.136.128.33";
        dnsname = "afs01.ist.utl.pt";
      }
      {
        ip = "193.136.128.34";
        dnsname = "afs02.ist.utl.pt";
      }
      {
        ip = "193.136.128.35";
        dnsname = "afs03.ist.utl.pt";
      }
      {
        ip = "193.136.128.36";
        dnsname = "afs04.ist.utl.pt";
      }
    ];
  };

  # Setup Kerberos
  krb5 = {
    enable = true;
    libdefaults = {
      default_realm = "IST.UTL.PT";
      dns_fallback = true;
      forwardable = true;

      # Required for SSH authentication into sigma
      dns_canonicalize_hostname = true;
      rnds = true;
    };

    realms = {
      "IST.UTL.PT" = {default_domain = "kerberos.tecnico.ulisboa.pt";};
    };
  };

  # Setup LDAP
  users.ldap = {
    enable = true;
    base = "dc=ist,dc=utl,dc=pt";
    server = "ldaps://ldap.tecnico.ulisboa.pt";
    nsswitch = false;
    loginPam = false;
  };

  environment.systemPackages = with pkgs; [openldap];

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
      krb5_realm = ${config.krb5.libdefaults.default_realm}
      krb5_server = ${config.krb5.realms.${config.krb5.libdefaults.default_realm}.default_domain}
    '';
  };

  # Setup PAM login
  security.pam.services.login.startSession = true;
  security.pam.krb5.enable = false; # Use SSSD instead

  # Get AFS ticket from Kerberos on login and ssh
  security.pam.services.login.text = lib.mkDefault (lib.mkAfter ''
    session optional ${pkgs.pam_afs_session}/lib/security/pam_afs_session.so program=${config.services.openafsClient.packages.programs}/bin/aklog nopag
    session optional pam_exec.so ${pkgs.subidappend}/bin/subidappend
  '');
  security.pam.services.sshd.text = lib.mkDefault (lib.mkAfter ''
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
    # Note: CPUQuota is not set here because percentages are relative to one CPU, not the total amount of resources

    CPUWeight = 50; # default is 100
    IOWeight = 50; # default is 100
  };

  # Ensure one user can't prevent the others from working
  # These settings constrain resources consumed by *each* user (each user-<UID>.slice),
  # after applying constrains higher in the hierarchy
  systemd.slices."user-".sliceConfig = {
    # Set a low-ball soft limit on memory usage.
    # When this limit is exceeded, memory used by user processes will be reclaimed aggressively
    MemoryHigh = "6%"; # 2GB * 5% ≃ 100MB

    # For the hard memory limit, we give more leeway.
    MemoryMax = "15%"; # 2GB * 15% ≃ 300MB
  };

  # The root user should be able to perform maintenance:
  # we override the previous defaults with higher limits for this.
  # Note that this only applies to processes created under login shells (through SSH, serial console, TTYs, etc.)
  systemd.slices."user-0".sliceConfig = {
    MemoryHigh = "infinity";
    MemoryMax = "infinity";

    # give more priority to root CPU/IO
    CPUWeight = 200; # default is 100
    IOWeight = 200; # default is 100
  };
}
