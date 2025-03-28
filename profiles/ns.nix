{pkgs,...}:{
    options={};
    config={
        rnl.githook = {
            enable = true;
            hooks.dns-config = {
                url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/dns.git";
                path = "/var/lib/dns-config";
                directoryMode = "0755";
            };
        };

        services.bind={
            enable = true;
            zones = {
                "127.zone"={};
                "admin-rnl.tecnico.ulisboa.pt"={
                    file="${hooks.dns-config.path}/admin-rnl.tecnico.ulisboa.pt";
                };
                "dmz-rnl.tecnico.ulisboa.pt"={};
                "gia-rnl.tecnico.ulisboa.pt"={};
                "global-rnl.tecnico.ulisboa.pt"={};
                "labs-rnl.tecnico.ulisboa.pt"={};
                "laptops-rnl.tecnico.ulisboa.pt"={};
                "localhost.zone"={};
                "mgmt-rnl.tecnico.ulisboa.pt"={};
                "priv-rnl.tecnico.ulisboa.pt"={};
                "pub-rnl.tecnico.ulisboa.pt"={};
                "reserved-rnl.tecnico.ulisboa.pt"={};
                "rkc-rnl.tecnico.ulisboa.pt"={};
                "priv-rnl.tecnico.ulisboa.pt"={};


            };
        };
    };
}
