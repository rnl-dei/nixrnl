{ buildGoModule, fetchgit, ... }:
buildGoModule rec {
  name = "wheatley";

  src = fetchgit {
    url = "https://gitlab.rnl.tecnico.ulisboa.pt/rnl/wheatley.git";
    sha256 = "sha256-dbo53wz+VNO4q3X+kHWbMl9aGVu2NHh5Pksx+bxSVQg=";
  };

  vendorHash = "sha256-o5fw41KqzZvu6u3qelyQTmOJOc1wCOVp/YBaDtDVlLk=";
}
