{ pkgs, ... }:
let
  pkg =
    (pkgs.coredns.overrideAttrs (

      {
        buildInputs = [ pkgs.unbound ];

      })).override
      {
        externalPlugins = [
          {
            name = "unbound";
            repo = "github.com/coredns/unbound";
            version = "v0.0.7";
          }
        ];
        vendorHash = "sha256-EHug1xXl2Oxlo660VKkGlCCnn0ydMk8jV3KEdi6CPnw=";
      };
in
{
  options = { };
  config = {
    rnl.githook = {
      enable = true;
      hooks.dns-config = {
        url = "git@gitlab.rnl.tecnico.ulisboa.pt:rnl/infra/dns.git";
        path = "/var/lib/dns-config";
        directoryMode = "0755";
      };
    };

    services.coredns = {
      package = pkg;
      enable = true;
      config = builtins.readFile ./coreconfig;
    };
  };
}
