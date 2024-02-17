{
  config,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    core.rnl
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  # Networking
  networking.interfaces.enp1s0 = {
    ipv4 = {
      addresses = [
        {
          address = "193.136.164.90";
          prefixLength = 26;
        }
      ];
      routes = [
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "193.136.164.126";
        }
      ];
    };
    ipv6 = {
      addresses = [
        {
          address = "2001:690:2100:81::90";
          prefixLength = 64;
        }
      ];
      routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "2001:690:2100:81::ffff:1";
        }
      ];
    };
  };

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Gestão das VMs com ansible";
    createdBy = "nuno.alves";

    interfaces = [{source = "priv";}];
    disks = [
      {source.dev = "/dev/zvol/dpool/volumes/dealer";}
      {
        type = "file";
        source.file = "/mnt/data/trantor.img";
      }
      {
        type = "file";
        source.file = "/mnt/data/cerebro.img";
      }
    ];
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
  };

  age.secrets."root-at-dealer-ssh.key" = {
    file = ../secrets/root-at-dealer-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  environment.systemPackages = let
    ansible = pkgs.ansible.override {
      windowsSupport = true;
    };
  in [
    ansible
  ];
}
