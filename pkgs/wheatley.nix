{
  buildGoModule,
  fetchgit,
  ...
}:
buildGoModule rec {
  name = "wheatley";

  src = fetchgit {
    url = "https://gitlab.rnl.tecnico.ulisboa.pt/rnl/wheatley.git";
    sha256 = "sha256-pr/CCCDGN5mw60cVn0TXhOpNxI+X41X0U1GIhEUERB8=";
  };

  vendorHash = "sha256-5EFsPk9XUqgC9qdE0gIc7baq/W+FYeirsN2WFTVAkK8=";
}
