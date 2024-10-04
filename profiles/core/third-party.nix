{ ... }:
{
  imports = [ ./rnl.nix ];

  # Override the default label "rnl" with "third-party".
  rnl.labels.core = "third-party";
}
