{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    magicavoxel = {
      url = "https://github.com/ephtracy/ephtracy.github.io/releases/download/0.99.7/MagicaVoxel-0.99.7.1-win64.zip";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      unstable-nocuda = import inputs.nixpkgs-unstable {
        inherit system;
      };
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          unstable.logseq
          unstable.obsidian
          unstable.thunderbird
          # no focalboard package on nix. and it don't work with nix-alien stuff
          unstable.krita
          unstable.blender
          unstable.godot_4
          unstable-nocuda.obs-studio
          unstable-nocuda.libsForQt5.kdenlive
          mpv

          libreoffice-qt

          (pkgs.writeShellScriptBin "magicavoxel" ''
            ${pkgs.wine64Packages.unstable}/bin/wine64 ${inputs.magicavoxel}/MagicaVoxel.exe
          '')
          pkgs.wine64Packages.unstable
          pkgs.winePackages.unstable
        ];
      };
    });
}
