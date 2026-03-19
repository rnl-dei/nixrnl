{ profiles, generateVlans, ... }:
{
  imports = with profiles; [
    type.ceph-tumbleweed
    ceph.s3gateway.master
  ];
  environment.etc = generateVlans [
    "public"
    "labs"
    "dmz"
    "gia"
    "portateis"
  ];
}
