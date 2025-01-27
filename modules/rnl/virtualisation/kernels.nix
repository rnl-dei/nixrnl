{ pkgs, ... }:
{
  minimal = pkgs.fetchurl {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/tmp/kernel-minimal";
    sha256 = "04bz6b4s0cjz9844q118l4s9j689dlxgcsk6s2ypkdany86ply6m";
  };
  shell = pkgs.fetchurl {
    url = "https://ftp.rnl.tecnico.ulisboa.pt/tmp/kernel-shell";
    sha256 = "0cfywp97lnvp7zs53x8kkg3j5yj7yqgwa18rlhpcy1zw57jik4ns";
  };
}
