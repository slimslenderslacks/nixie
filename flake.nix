{
  description = "nixie";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "nixie";
          packages = with pkgs; [ babashka clojure pkgs.graalvmCEPackages.graalvm17-ce clojure-lsp temurin-bin neovim rnix-lsp ];

          shellHook = ''
            echo "babashka `${pkgs.babashka}/bin/bb --version`";
            export GRAALVM_HOME=${pkgs.graalvmCEPackages.graalvm17-ce};
            export DEV_ENV=nixie
          '';
        };
      });
}
