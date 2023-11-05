{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          yuzu-mainline
          # yuzu-early-access

          (pkgs.steam.override {
            extraLibraries = pkgs:
              with pkgs; [
                libxkbcommon
                mesa
                wayland
                # (sndio.overrideAttrs (new: old: {
                #   postFixup =
                #     old.postFixup
                #     + ''
                #       ln -s $out/lib/libsndio.so $out/lib/libsndio.so.6.1
                #     '';
                # }))
                sndio
              ];
          })
          .run
          # steam-run

          steam
          winetricks

          # pkg-config
          # gnome3.adwaita-icon-theme

          # lutris
          unstable.mangohud
          (lutris.override {
            extraLibraries = pkgs: [
              # List library dependencies here
              # pkg-config
              # gst_all_1.gstreamer
              # gst_all_1.gst-plugins-base
              # gst_all_1.gst-plugins-bad
              # gst_all_1.gst-plugins-good
              # gst_all_1.gst-plugins-ugly
            ];
          })
        ];
      };
    });
}
