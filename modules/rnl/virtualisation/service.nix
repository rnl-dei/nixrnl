{
  pkgs,
  lib,
  ...
}: {
  arch,
  autostart,
  boot,
  cpu,
  createdBy,
  description,
  disks,
  features,
  graphics,
  installer,
  interfaces,
  machine,
  maxMemoryDiff,
  memory,
  name,
  timeout,
  uefi,
  vcpu,
  directKernel,
  ...
}: let
  mkInterface = options: ''
    <interface type='${options.type}'>
      ${lib.optionalString (options.mac != null) "<mac address='${options.mac}'/>"}
      ${lib.optionalString (options.type == "bridge") "<source bridge='${options.source}'/>"}
      ${lib.optionalString (options.type == "network") "<source network='default'/>"}
      <model type='virtio'/>
      <address type='${options.addressType}' ${lib.optionalString (options.addressBus != null) "bus='${options.addressBus}'"} ${lib.optionalString (options.addressSlot != null) "slot='${options.addressSlot}'"} />
    </interface>
  '';

  mkDisk = options: ''
    <disk type='${options.type}' device='${options.device}'>
      <driver name='qemu' type='${options.driverType}'/>
      ${lib.optionalString (options.type == "file") "<source file='${toString options.source.file}'/>"}
      ${lib.optionalString (options.type == "block") "<source dev='${options.source.dev}'/>"}
      <target dev='${options.target.dev}' bus='${options.target.bus}'/>
      ${lib.optionalString (options.bootOrder != null && boot == []) "<boot order='${toString options.bootOrder}'/>"}
    </disk>
  '';

  cdrom = lib.optionals (installer != null) [
    {
      device = "cdrom";
      type = "file";
      driverType = "raw";
      readonly = true;
      source.file = installer;
      target.dev = "sda";
      target.bus = "sata";
      bootOrder = 99;
    }
  ];

  disks' = disks ++ cdrom;

  xmlConfigFile = pkgs.writeText "libvirt-guest-${name}.xml" (''
      <domain type='kvm'>
        <name>${name}</name>
        <uuid>UUID</uuid>
        <description>${description} ${lib.optionalString (createdBy != null) "(created by ${createdBy})"}</description>
        <memory unit='MiB'>${toString (memory + maxMemoryDiff)}</memory>
        <currentMemory unit='MiB'>${toString memory}</currentMemory>
        <vcpu placement='static'>${toString vcpu}</vcpu>
        <os>
          <type arch='${arch}' machine='pc-${machine}-8.0'>hvm</type>
          ${lib.optionalString uefi "<loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>"}
    ''
    + lib.concatMapStringsSep "\n" (option: "<boot dev='${option}' />") boot
    + lib.optionalString (directKernel.kernel != null) "<kernel>${toString directKernel.kernel}</kernel>"
    + lib.optionalString (directKernel.initrd != null) "<initrd>${directKernel.initrd}</initrd>"
    + lib.optionalString (directKernel.cmdline != null) "<cmdline>${directKernel.cmdline}</cmdline>"
    + ''
      </os>
      <features>
        ${lib.concatMapStringsSep "\n" (feature: "<${feature}/>") features}
      </features>
      <cpu mode='${cpu}' check='none'/>
      <clock offset='utc'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-${arch}</emulator>
    ''
    + (lib.concatMapStringsSep "\n" mkInterface interfaces)
    + (lib.concatMapStringsSep "\n" mkDisk disks')
    + (lib.optionalString (graphics.type == "spice") ''
      <graphics type='spice' autoport='yes' listen='${graphics.address}'>
        <listen type='address' address='${graphics.address}'/>
      </graphics>
    '')
    + ''
          <console type="pty">
            <target type="virtio" port="0"/>
          </console>
          <input type="mouse" bus="ps2"/>
          <input type="keyboard" bus="ps2"/>
          <rng model="virtio">
            <backend model="random">/dev/urandom</backend>
          </rng>
        </devices>
      </domain>
    '');
in {
  after = ["libvirtd.service"];
  requires = ["libvirtd.service"];
  wantedBy = ["multi-user.target"];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  script = ''
    uuid="$(${pkgs.libvirt}/bin/virsh domuuid '${name}' || true)"
    ${pkgs.libvirt}/bin/virsh define <(sed "s/UUID/$uuid/" '${xmlConfigFile}')
    ${pkgs.libvirt}/bin/virsh autostart ${lib.optionalString (!autostart) "--disable"} '${name}'
  '';
}
