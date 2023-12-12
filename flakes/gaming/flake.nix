{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{...
  }:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
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
          yuzu-early-access

          steam-pkg
          steam-pkg.run

          # steam
          # steam-run

          winetricks

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
        ];
      };
    });
}
