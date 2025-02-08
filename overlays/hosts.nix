{ inputs, argsPkgs, ... }:
final: _prev: {
  unstable = import inputs.unstable { inherit (final) system; } // argsPkgs;
  allowOpenSSL =
    import inputs.nixpkgs {
      inherit (final) system;
      config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

    }
    // argsPkgs;
  allowSquid =
    import inputs.nixpkgs {
      inherit (final) system;
      config.permittedInsecurePackages = [ "squid-5.9" ];
    }
    // argsPkgs;
}
