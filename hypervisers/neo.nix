{ profiles, ... }:
{
  imports = with profiles; [
    type.ceph-tumbleweed
    ceph.s3gateway
  ];
}
