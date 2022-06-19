{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # see https://serokell.io/blog/practical-nix-flakes
  # note that the `inputsFrom` in `mkShell` is a bit different
  # because to get the *real* build dependencies set up correctly
  # we need the .env property of the package - not sure what's up with that
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskellPackages;
        packageName = "http3";
      in
        {
          packages.${packageName} =
                haskellPackages.callCabal2nix packageName self rec { };

          defaultPackage = self.packages.${system}.${packageName};

          devShell = pkgs.mkShell
          {
            buildInputs = with haskellPackages;
              [ cabal-install
                hoogle
                ormolu
                haskell-language-server
              ];
            inputsFrom = [self.packages.${system}.${packageName}.env];
          };
        }
    );
}
