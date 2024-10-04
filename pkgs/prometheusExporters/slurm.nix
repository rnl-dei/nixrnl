{
  buildGoModule,
  fetchFromGitHub,
  lib,
  slurm,
  ...
}:
buildGoModule rec {
  pname = "prometheus-slurm-exporter";
  version = "0.20";
  rev = version;

  src = fetchFromGitHub {
    inherit rev;
    owner = "vpenso";
    repo = "prometheus-slurm-exporter";
    sha256 = "sha256-KS9LoDuLQFq3KoKpHd8vg1jw20YCNRJNJrnBnu5vxvs=";
  };

  buildInputs = [ slurm ];

  doCheck = false;

  vendorHash = "sha256-A1dd9T9SIEHDCiVT2UwV6T02BSLh9ej6LC/2l54hgwI=";

  meta = with lib; {
    description = "Prometheus SLURM exporter";
    license = licenses.gpl3;
    maintainers = [ "nuno.alves" ];
  };
}
