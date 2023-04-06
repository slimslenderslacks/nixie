{
  description = "{{description}}";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
	{{ lets }}
      in
      {
        devShells.default = pkgs.mkShell {
          name = "nixie";
          packages = with pkgs; [ {{packages}} ];

          shellHook = ''
	    {{ shell-hook }}
            export DEV_ENV=nixie
          '';
        };
      });
}
