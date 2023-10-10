{
  pkgs,
  lib,
  config,
  nixosConfigurations,
  ...
} @ args:
with lib; let
  cfg = config.rnl.virtualisation;

  vmOptions = {
    description = mkOption {
      type = types.str;
      description = "Description of the virtual machine";
    };

    createdBy = mkOption {
      type = types.nullOr types.str;
      default = "rnl";
      description = "Creator of the virtual machine";
    };

    maintainers = mkOption {
      type = types.listOf types.str;
      default = ["rnl"];
      description = "List of maintainers";
    };

    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Autostart the virtual machine";
    };

    timeout = mkOption {
      type = types.ints.positive;
      default = 30;
      description = "Timeout in seconds to wait for the virtual machine to shutdown";
    };

    arch = mkOption {
      type = types.enum ["x86_64" "aarch64"];
      default = "x86_64";
      description = "Architecture of the virtual machine";
    };

    machine = mkOption {
      type = types.enum ["q35" "i440fx"];
      default = "q35";
      description = "Machine type";
    };

    uefi = mkOption {
      type = types.bool;
      default = true;
      description = "Enable UEFI";
    };

    boot = mkOption {
      type = types.listOf (types.enum ["hd" "cdrom"]);
      default = ["hd" "cdrom"];
      description = "Boot order";
    };

    memory = mkOption {
      type = types.ints.positive;
      default = 2048;
      description = "Amount of memory in MiB";
    };

    maxMemoryDiff = mkOption {
      type = types.ints.positive;
      default = 4096;
      description = "Maximum memory difference in MiB";
    };

    vcpu = mkOption {
      type = types.ints.positive;
      default = 2;
      description = "Number of virtual CPUs";
    };

    cpu = mkOption {
      type = types.enum ["host-model" "host-passthrough"];
      default = "host-passthrough";
      description = "CPU mode";
    };

    features = mkOption {
      type = types.listOf types.str;
      default = ["acpi"];
      description = "List of features";
      example = ["acpi" "apic" "pae"];
    };

    graphics = {
      type = mkOption {
        type = types.enum ["none" "spice"];
        default = "spice";
        description = "Graphics type";
      };

      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Graphics address";
      };
    };

    directKernel = {
      kernel = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Kernel image";
      };
      initrd = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Initrd image";
      };
      cmdline = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Kernel command line";
      };
    };

    disks = mkOption {
      type = types.listOf (types.submodule {options = diskOptions;});
      default = [];
      description = "List of disks";
      example = [
        {
          source = {dev = "/dev/zvol/zroot/vms/example";};
          target = {dev = "vda";};
          size = 20;
          bootOrder = 1;
        }
      ];
    };

    cdroms = mkOption {
      type = types.nullOr (types.listOf types.path);
      default = [];
      description = "List of CD-ROMs. Support up to 4 CD-ROMs.";
      example = ["/path/to/image.iso" config.rnl.virtualisation.images.nixos-live];
    };

    interfaces = mkOption {
      type = types.listOf (types.submodule {options = interfaceOptions;});
      default = [];
      description = "List of network interfaces";
      example = [
        {
          source = "dmz";
          target = "vm-example";
        }
      ];
    };
  };

  diskOptions = {
    device = mkOption {
      type = types.enum ["disk" "cdrom"];
      default = "disk";
      description = ''
        Disk device
        If you want to use a cdrom, you must use the cdroms option.
      '';
    };

    type = mkOption {
      type = types.enum ["block" "file"];
      default = "block";
      description = "Disk type";
    };

    driverType = mkOption {
      type = types.enum ["raw"];
      default = "raw";
      description = "Disk driver type";
    };

    source = {
      file = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Disk source file";
      };

      dev = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Disk source device";
      };
    };

    target = {
      dev = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Disk target device
          If not set, the device will be automatically assigned based on the
          position in the list of disks and the disk device option.
        '';
      };

      bus = mkOption {
        type = types.enum ["sata" "virtio"];
        default = "virtio";
        description = "Disk target bus";
      };
    };

    readOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Read only";
    };

    size = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "Disk size in GiB";
    };

    bootOrder = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Boot order";
    };
  };

  interfaceOptions = {
    type = mkOption {
      type = types.enum ["bridge" "network"];
      description = "Network type";
      default = "bridge";
    };

    source = mkOption {
      type = types.str;
      description = "Network source";
    };

    mac = mkOption {
      type = types.nullOr types.str;
      description = "Network mac address";
      default = null;
    };

    target = mkOption {
      type = types.nullOr types.str;
      description = "Network target. Interface name at the host";
    };

    addressType = mkOption {
      type = types.enum ["pci"];
      description = "Network address type";
      default = "pci";
    };

    addressBus = mkOption {
      type = types.nullOr types.str;
      description = "Network address bus";
      default = null;
    };

    addressSlot = mkOption {
      type = types.nullOr types.str;
      description = "Network address slot";
      default = null;
    };
  };

  hosts =
    lib.mapAttrs (_: host: host.config.rnl.virtualisation.guest)
    (lib.filterAttrs (
        _: host:
          host.config.rnl.labels.location
          == config.networking.hostName
          && host.config.rnl.labels.type == "vm"
      )
      nixosConfigurations);

  services =
    lib.mapAttrs' (name: config: {
      name = "libvirt-guest@${name}";
      value = (import ./service.nix args) (config // {inherit name;});
    })
    hosts;
in {
  options.rnl.virtualisation = {
    enable = mkEnableOption "RNL Virtualisation";
    hosts = mkOption {
      type = types.attrsOf (types.submodule {options = vmOptions;});
      default = hosts;
      readOnly = true;
      description = "Virtual machines";
    };
    guest = mkOption {
      type = types.nullOr (types.submodule {options = vmOptions;});
      default = null;
      description = "Guest virtual machine";
    };
    images = mkOption {
      type = types.attrsOf types.path;
      default = import ./images.nix args;
      description = "Iso images to boot from";
      example = {
        "ubuntu-22.04" = pkgs.fetchurl {
          url = "https://ftp.rnl.tecnico.ulisboa.pt/pub/ubuntu/releases/23.04/ubuntu-23.04-live-server-amd64.iso";
          sha256 = "0srl1p42p65yl4c3isn9y2zb6968r4zqlf34b5kdkmx6jj2a9kf7";
        };
      };
    };
    kernels = mkOption {
      type = types.attrsOf types.path;
      default = import ./kernels.nix args;
      description = "Kernels to boot from";
      example = {
        "minimal" = pkgs.fetchurl {
          url = "https://ftp.rnl.tecnico.ulisboa.pt/tmp/kernel-minimal";
          sha256 = "04bz6b4s0cjz9844q118l4s9j689dlxgcsk6s2ypkdany86ply6m";
        };
        "shell" = pkgs.fetchurl {
          url = "https://ftp.rnl.tecnico.ulisboa.pt/tmp/kernel-shell";
          sha256 = "0cfywp97lnvp7zs53x8kkg3j5yj7yqgwa18rlhpcy1zw57jik4ns";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.guest == null;
        message = "RNL Virtualisation: Cannot enable both host and guest virtual machines";
      }
    ];

    systemd.services = services;
  };
}
