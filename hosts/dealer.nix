{
  config,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm

    ist.afs
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.90";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::90";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Gestão das VMs com ansible";
    createdBy = "nuno.alves";

    interfaces = [ { source = "priv"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/dealer"; } ];
  };

  rnl.githook = {
    enable = true;
    hooks.ansible-infra.url = "git@gitlab.rnl.tecnico.ulisboa.pt:/rnl/infra/ansible.git";
    hooks.ansible-windows.url = "git@gitlab.rnl.tecnico.ulisboa.pt:/rnl/windows/ansible.git";
  };

  age.secrets."ansible-infra-vault-pass.txt" = {
    file = ../secrets/ansible-infra-vault-pass-txt.age;
    path = config.rnl.githook.hooks.ansible-infra.path + "/.vault_pass.txt";
  };

  age.secrets."ansible-windows-vault-pass.txt" = {
    file = ../secrets/ansible-windows-vault-pass-txt.age;
    path = config.rnl.githook.hooks.ansible-windows.path + "/.vault_pass.txt";
  };

  programs.bash.shellAliases = {
    ansible-infra = "ANSIBLE_CONFIG=${config.rnl.githook.hooks.ansible-infra.path}/ansible.cfg ansible";
    ansible-windows = "ANSIBLE_CONFIG=${config.rnl.githook.hooks.ansible-windows.path}/ansible.cfg ansible";

    ssh-windows-labs = "ssh -p 2222 -o User='Admin'";
  };

  age.secrets."root-at-dealer-ssh.key" = {
    file = ../secrets/root-at-dealer-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  environment.systemPackages =
    let
      ansible = pkgs.ansible.override { windowsSupport = true; };
    in
    [ ansible ];

  # Discoverafsd
  systemd.services.discoverafsd = {
    description = "DiscoverAFS daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DISCOVERAFSD_DIR = "/var/lib/discoverafsd";
    };

    serviceConfig = {
      ExecStart = "${pkgs.discoverafsd}/bin/discoverafsd.sh";
      Restart = "on-failure";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.systemd.services.discoverafsd.environment.DISCOVERAFSD_DIR} 0755 root root"
  ];
}
