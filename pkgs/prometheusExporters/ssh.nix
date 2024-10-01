{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}:
buildGoModule rec {
  pname = "prometheus-ssh-exporter";
  version = "1.5.0";
  rev = "v${version}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "treydock";
    repo = "ssh_exporter";
    sha256 = "sha256-avvHkJLsafYsruJY1cMVQhCw5dktEypXh7kSH+Ad7XY=";
  };

  vendorHash = "sha256-BD47utPlBxp7vm/atI9W00fr0U800rGhZzs1Fhg2TwE=";

  meta = with lib; {
    description = "Prometheus SSH exporter";
    license = licenses.asl20;
    maintainers = ["martim.monis"];
  };
}
