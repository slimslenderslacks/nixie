{
  description = "nixie";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    github-linguist.url = "github:slimslenderslacks/linguist";
    clj-nix = {
      url = "github:jlesquembre/clj-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, github-linguist, clj-nix }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
	cljpkgs = clj-nix.packages."${system}";
      in
      {
        packages = {
          clj = cljpkgs.mkCljBin {
            projectSrc = ./.;
            name = "slimslenderslacks/nixie";
            main-ns = "nixie.core";
            jdkRunner = pkgs.jdk17_headless;
	    # attributs go straight to mkDeriviation
	    doCheck = true;
	    checkPhase = "clj -M:test";
	    nativeBuildInputs = [ pkgs.makeWrapper ];
	    buildCommand = "clj -T:build uber";
            postInstall = ''
	      wrapProgram $cljBinary --set PATH ${pkgs.lib.makeBinPath [ github-linguist.packages.aarch64-darwin.default ]}
	    '';
          };

          graal = cljpkgs.mkGraalBin {
            cljDrv = self.packages."${system}".clj;
   	    nativeBuildInputs = [ pkgs.makeWrapper ];
	    preBuild = ''
cat <<EOF > reflect-config.json
[]
EOF
	    '';
            postInstall = ''
	      wrapProgram $out/bin/nixie --set PATH ${pkgs.lib.makeBinPath [ github-linguist.packages.aarch64-darwin.default ]}
	    '';
	    extraNativeImageBuildArgs = ["-H:-CheckToolchain" 
	                                 "-H:+ReportExceptionStackTraces" 
					 "--native-image-info" 
					 "--no-fallback" 
					 "--initialize-at-build-time" 
					 "--verbose" 
					 "--enable-http" 
					 "--enable-https"
					 "-H:ReflectionConfigurationFiles=reflect-config.json"];
          };

	  # not used directly - mkCljBin uses this to pull maven deps into the nix store
	  clj-cache = cljpkgs.mk-deps-cache {
            lockfile = ./deps-lock.json;
          };
	};
        devShells.default = pkgs.mkShell {
          name = "nixie";
          packages = with pkgs; [ babashka clojure pkgs.graalvmCEPackages.graalvm17-ce clojure-lsp temurin-bin neovim github-linguist.packages.aarch64-darwin.default ];

          shellHook = ''
            export GRAALVM_HOME=${pkgs.graalvmCEPackages.graalvm17-ce};
          '';
        };
      });
}
