{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
      };

      manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
    in {
      packages.default = unstable.rustPlatform.buildRustPackage {
        pname =  "until-window-class-detected";
        # pname = manifest.name;
        version = manifest.version;
        cargoLock.lockFile = ./Cargo.lock;
        src = pkgs.lib.cleanSource ./.;
      };

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs;
          [
            unstable.rust-analyzer
            unstable.rustfmt
            unstable.clippy
          ]
          ++ self.packages."${system}".default.nativeBuildInputs
          ++ self.packages."${system}".default.buildInputs;
        shellHook = ''
          export RUST_BACKTRACE="1"
        '';
      };
    });
}
