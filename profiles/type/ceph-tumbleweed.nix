{
  config,
  lib,
  rnl-keys,
  ...
}:
{
  nixpkgs.config = {
    build-users-group = "nixbld";
  };
  environment.etc."ssh/authorized_keys.d/root" = {
    text = lib.strings.concatStrings (
      rnl-keys.rnl-keys
      ++ [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDGSDWwlhWAUUHK8e5g19U9E63AIW8ctyDoYY8kdYNDnvBg0AtwcVa1VQ0z6PxJp00i+doNuy6vFPLgSHH3CkGqYKdzGiluy1hCzBQsdPpsSn1r3GDVifjYkBw6/lPhKiV0SMeBXq2dkMxSoCpbGW7X/fJOMBkm5dBEWJF32Qr8WC/euUI1Trs1ddX/fet2alJd4xtDqA8kBCs8umblLolch7//f1riNljqesQ5VA2nR/7nqNooL+nRURZgC62N+VasPeGUE0ESa/Gad/Cb1frPDnDTJzOgyWz97wAfoQHRasJUcof2AtvO+8SYmPcDeRLaq4SZYQthYvoCpn27rUlaZ6C4VQ9oTL9SBGfa/IfJb4KYB5Vm3MyadhXdgn7T7H/MTkHoFIu5c6V6G9mqy/+o55ahKZOUX1FqLu8O5a14DIHkmBhOcpa+XTIFQvUgKnStGoy5d2aCc0QvkS2VVjjYtuIT+C1UtUYzHC+Dfgn4xWgchzZ42Ih2BW1Yo2Lx/E= ceph-0dcbb900-fada-11f0-a19f-826bd3acc737"
      ]
    );
  };
}
