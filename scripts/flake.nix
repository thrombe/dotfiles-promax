{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
      };
      # unstable = import inputs.nixpkgs-unstable {
      #   inherit system;
      # };

      # helpers
      flakeDefaultPackage = flake: flake.packages."${system}".default;

      # flake inputs for these imported flakes has to be added in current flake
      wait-until = import ./libwmctl_test; # default.nix using flake-compat
    in {
      packages = {
        wait-until = flakeDefaultPackage wait-until;
      };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          (python311.withPackages (ps:
            with ps; [
            ]))
          python311Packages.python-lsp-server
          python311Packages.ruff-lsp # python linter
          python311Packages.black # python formatter
        ];
      };
    });
}
