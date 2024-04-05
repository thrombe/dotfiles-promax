{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      overlay-unstable = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          # config.allowUnfree = true;
        };
      };
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          overlay-unstable
        ];
      };

      # helpers
      flakeDefaultPackage = flake: flake.packages."${system}".default;

      # flake inputs for these imported flakes has to be added in current flake
      wait-until = import ./libwmctl_test; # default.nix using flake-compat

      # - [nixpkgs/pkgs/build-support/writers/scripts.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/writers/scripts.nix)
      pythonScript = libraries: name: content:
        pkgs.writers.makeScriptWriter {
          interpreter = (pkgs.python311.withPackages (ps: libraries)).interpreter;
        }
        "/bin/${name}"
        content;
    in {
      packages = {
        wait-until = flakeDefaultPackage wait-until;
        lbwopen-links =
          pythonScript (with pkgs; [
              python311Packages.pyperclip
              python311Packages.colorama
            ]) "lbwopen-links"
            ./librewolf_open_links.py;
      };

      devShells.default = pkgs.mkShell {
        packages =
          (with pkgs; [
            (python311.withPackages (ps:
              with ps; [
              ]))
            python311Packages.python-lsp-server
            python311Packages.ruff-lsp # python linter
            python311Packages.black # python formatter
          ])
          ++ pkgs.lib.attrValues self.packages.${system};
      };
    });
}
