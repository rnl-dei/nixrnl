{ pkgs, profiles, ... }:
{
  imports = with profiles; [
    core.dei
    filesystems.simple-uefi
    os.nixos
    type.vm
  ];

  # Networking
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "193.136.164.107";
          prefixLength = 26;
        }
      ];
      ipv6.addresses = [
        {
          address = "2001:690:2100:81::107";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway.address = "193.136.164.126";
    defaultGateway6.address = "2001:690:2100:81::ffff:1";
  };

  rnl.labels.location = "chapek";

  rnl.virtualisation.guest = {
    description = "Gestão de configuração para o DEI";

    interfaces = [ { source = "priv"; } ];
    disks = [ { source.dev = "/dev/zvol/dpool/volumes/thomas"; } ];
  };

  rnl.githook = {
    enable = true;
    hooks.ansible = {
      url = "git@gitlab.rnl.tecnico.ulisboa.pt:/dei/infra/ansible.git";
      path = "/etc/ansible";
    };
  };

  age.secrets."root-at-thomas-ssh.key" = {
    file = ../secrets/root-at-thomas-ssh-key.age;
    path = "/root/.ssh/id_ed25519";
    owner = "root";
  };

  environment.systemPackages =
    let
      ansible = pkgs.ansible.override { windowsSupport = true; };
    in
    [
      ansible
      (pkgs.writeScriptBin "deploy" ''
        FLAGS=""

        POSITIONAL=()
        while [[ $# -gt 0 ]]
        do
        key="$1"

        case $key in
            -w|--windows)
            FLAGS="$FLAGS --ask-vault-pass"
            shift
            ;;
            -c|--check)
            FLAGS="$FLAGS --check --diff"
            shift
            ;;
            *)
            FLAGS="$FLAGS -l $1"
            shift
            ;;
        esac
        done
        set -- "''${POSITIONAL[@]}" # restore positional parameters

        if [[ -z $FLAGS ]]
        then
                FLAGS="$FLAGS --ask-vault-pass"
        fi

        ${ansible}/bin/ansible-playbook $FLAGS /etc/ansible/site.yml
      '')
    ];

  users.motd = ''

    [0;32mDeploys do Ansible do DEI:[0m
    [1;34m	deploy [[4mHOST_PATTERN][0m [-w|--windows] [-c|--check]

  '';
}
