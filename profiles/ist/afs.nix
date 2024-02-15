{...}: {
  # Setup AFS
  services.openafsClient = {
    enable = true;
    mountPoint = "/afs";
    cellName = "ist.utl.pt";
    cellServDB = [
      {
        ip = "193.136.128.33";
        dnsname = "afs01.ist.utl.pt";
      }
      {
        ip = "193.136.128.34";
        dnsname = "afs02.ist.utl.pt";
      }
      {
        ip = "193.136.128.35";
        dnsname = "afs03.ist.utl.pt";
      }
      {
        ip = "193.136.128.36";
        dnsname = "afs04.ist.utl.pt";
      }
    ];
  };
}
