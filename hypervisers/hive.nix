{ profiles, ... }:
{
  imports = with profiles; [
    os.susetmbleweed
    type.ceph-tumbleweed
  ];

  rnl.labels.location = "inf1-p01-a2";

}
