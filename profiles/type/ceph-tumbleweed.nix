{
  lib,
  rnl-keys,
  ...
}:
let
  generateVlan = (
    {
      vlan,
      uuid,
      id,
      bridge,
    }:
    ''
      [connection]
      id=${vlan}
      uuid=${uuid}
      type=vlan
      master=${bridge}
      interface-name=${vlan}
      port-type=bridge
      timestamp=1771067691

      [ethernet]

      [vlan]
      flags=1
      id=${id}
      parent=br0

      [ipv4]
      method=disabled

      [ipv6]
      addr-gen-mode=default
      method=disabled
      [bridge-port]
    ''
  );

  generateBridge = (
    {
      bridge,
      uuid,
    }:
    ''
      [connection]
      id=${bridge}
      uuid=${uuid}
      type=bridge
      interface-name=${bridge}
      timestamp=1774050110

      [ethernet]

      [bridge]

      [ipv4]
      method=disabled

      [ipv6]
      addr-gen-mode=default
      method=disabled

      [proxy]
    ''
  );
in
{
  _module.args.generateVlans =
    vlans: ids: bridges:
    builtins.listToAttrs (
      lib.imap0 (i: vlan: {
        name = "NetworkManager/system-connections/${vlan}.nmconnection";
        value = {
          mode = "0600";
          text = generateVlan {
            vlan = vlan;
            uuid = lib.rnl.generateUUID vlan;
            id = builtins.elemAt ids i;
            bridge = builtins.elemAt bridges i;
          };
        };
      }) vlans
    );

  _module.args.generateBridges =
    list:
    builtins.listToAttrs (
      map (bridge: {
        name = "NetworkManager/system-connections/${bridge}.nmconnection";
        value = {
          mode = "0600";
          text = generateBridge {
            bridge = bridge;
            uuid = lib.rnl.generateUUID bridge;
          };
        };
      }) list
    );

  environment.etc = {
    "ssh/sshd_config.d/99-custom-keys.conf" = {
      mode = "0644";
      text = ''
        AuthorizedKeysFile .ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
      '';
    };
    "ssh/authorized_keys.d/root" = {
      mode = "0644";
      text = lib.strings.concatStringsSep "\n" (
        rnl-keys.rnl-keys
        ++ [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDGSDWwlhWAUUHK8e5g19U9E63AIW8ctyDoYY8kdYNDnvBg0AtwcVa1VQ0z6PxJp00i+doNuy6vFPLgSHH3CkGqYKdzGiluy1hCzBQsdPpsSn1r3GDVifjYkBw6/lPhKiV0SMeBXq2dkMxSoCpbGW7X/fJOMBkm5dBEWJF32Qr8WC/euUI1Trs1ddX/fet2alJd4xtDqA8kBCs8umblLolch7//f1riNljqesQ5VA2nR/7nqNooL+nRURZgC62N+VasPeGUE0ESa/Gad/Cb1frPDnDTJzOgyWz97wAfoQHRasJUcof2AtvO+8SYmPcDeRLaq4SZYQthYvoCpn27rUlaZ6C4VQ9oTL9SBGfa/IfJb4KYB5Vm3MyadhXdgn7T7H/MTkHoFIu5c6V6G9mqy/+o55ahKZOUX1FqLu8O5a14DIHkmBhOcpa+XTIFQvUgKnStGoy5d2aCc0QvkS2VVjjYtuIT+C1UtUYzHC+Dfgn4xWgchzZ42Ih2BW1Yo2Lx/E= ceph-0dcbb900-fada-11f0-a19f-826bd3acc737"
        ]
      );
    };
  };
}
