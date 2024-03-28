{
  fetchFromGithub,
  buildGoModule, lib,
  ...
}:
buildGoModule rec {
  pname = "prometheus-slurm-exporter";
  version = "0.20";
  rev = version;

  src = fetchFromGithub {
    inherit rev;
    owner = "vpenso";
    repo = "prometheus-slurm-exporter";
    sha256 = "";
  };

  vendorHash = "";

  meta = with lib; {
    description = "Slurm exporter for Prometheus";
    license = licenses.mit;
    maintainers = ["nuno.alves"];
  };
}
