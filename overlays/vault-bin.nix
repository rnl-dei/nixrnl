{...}: final: prev: {
  /*
  * Bump vault-bin to version >= 1.14.0 to allow ACME.
  * https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-acme-caddy
  */
  vault-bin = prev.vault-bin.overrideAttrs (old: rec {
    version = "1.14.0";

    src = prev.fetchzip {
      url = "https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip";
      sha256 = "sha256-odmXPzzxLzrFIGl7eUQNTkX6cxxLAGq6Rkx7UKkRqUY=";
    };
  });
}
