{ profiles, ... }:
{
  imports = with profiles; [
    type.ceph-tumbleweed
  ];
}
