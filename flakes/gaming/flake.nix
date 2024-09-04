{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs-yuzu.url = "github:nixos/nixpkgs/d44d59d2b5bd694cd9d996fd8c51d03e3e9ba7f7";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-yuzu = import inputs.nixpkgs-yuzu {
        inherit system;
      };

      steam-pkg = 
          (unstable.steam.override {
            extraLibraries = pkgs:
              with pkgs; [
                libxkbcommon
                mesa
                wayland
                sndio
              ];
          });
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # yuzu-mainline
          pkgs-yuzu.yuzu-early-access

          steam-pkg
          steam-pkg.run

          # steam
          # steam-run

          winetricks
          pkgs.wine64Packages.unstable
          pkgs.winePackages.unstable

          # pkg-config
          # gnome3.adwaita-icon-theme

          # lutris
          mangohud
          (lutris.override {
            extraLibraries = pkgs: [
              # List library dependencies here
              # pkg-config
            ];
          })

          renderdoc
          (pkgs.writeShellScriptBin "fugl" ''
            ./fugl.sh
          '')
        ];
      };
    });
}
