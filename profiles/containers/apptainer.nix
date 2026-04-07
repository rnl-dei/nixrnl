{ pkgs, ... }:
{
  programs.singularity = {
    enable = true;
    package = pkgs.apptainer;
  };
}
