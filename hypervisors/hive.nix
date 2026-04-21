{
  profiles,
  generateVlans,
  generateBridges,
  ...
}:
{
  imports = with profiles; [
    type.ceph-tumbleweed
    ceph.s3gateway.slave
  ];
  environment.etc =
    (generateVlans
      [
        "public-vlan"
        "labs-vlan"
        "dmz-vlan"
        "gia-vlan"
        "portateis-vlan"
      ]
      [ "30" "40" "50" "60" "70" ]
      [
        "pub"
        "labs"
        "dmz"
        "gia"
        "portateis"
      ]
    )
    // (generateBridges [
      "pub"
      "labs"
      "dmz"
      "gia"
      "portateis"
    ]);
}
