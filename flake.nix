{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskellPackages;
      in {
        packages.http3 =
          haskellPackages.callCabal2nix "http3" self rec { };

        defaultPackage = self.packages.${system}.http3;

        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages;
            [ cabal-install
              haskell-language-server
            ];
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      }
    );
}
