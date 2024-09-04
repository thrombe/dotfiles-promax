{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
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
          mpv

          unstable.thunderbird

          unstable.logseq
          unstable.obsidian
          # no focalboard package on nix. and it don't work with nix-alien stuff

          unstable.krita
          unstable.blender
          unstable.godot_4

          unstable-nocuda.obs-studio
          unstable-nocuda.libsForQt5.kdenlive

          unstable.wf-recorder
          unstable.slurp
          (pkgs.writeShellScriptBin "record-this-window" ''
            monitors=`hyprctl -j monitors`
            clients=`hyprctl -j clients | jq -r '[.[] | select(.workspace.id | contains('$(echo $monitors | jq -r 'map(.activeWorkspace.id) | join(",")')'))]'`
            boxes="$(echo $clients | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"')"
            geometry="$(slurp -r <<< "$boxes")"
            echo $geometry
            wf-recorder -g "$geometry" $@
          '')

          ventoy

          unstable.floorp
          libreoffice-qt

          # music apps
          spotube
          clementine
          unstable.nuclear
          (let
            pname = "moosync";
            version = "10.3.2";

            src = pkgs.fetchurl {
              url = "https://github.com/Moosync/Moosync/releases/download/v${version}/Moosync-${version}-linux-x86_64.AppImage";
              hash = "sha256-/7arMhmisJBxXpXVubz/scT7hQoKQirULbGEGLiMmZ4=";
            };

            appimageTools = pkgs.appimageTools;
            appimageContents = appimageTools.extract {inherit pname version src;};
          in
            appimageTools.wrapType2 {
              inherit pname version src;

              extraInstallCommands = ''
                install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
                substituteInPlace $out/share/applications/${pname}.desktop \
                  --replace 'Exec=AppRun' 'Exec=${pname}'
                cp -r ${appimageContents}/usr/share/icons $out/share
              '';
            })
          (let
            # bin/muffon-2.0.3
            pname = "muffon";
            version = "2.0.3";

            src = pkgs.fetchurl {
              url = "https://github.com/staniel359/muffon/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
              hash = "sha256-2eLe/xvdWcOcUSE0D+pMOcOYCfFVEyKO13LiaJiZgX0=";
            };

            appimageTools = pkgs.appimageTools;
            appimageContents = appimageTools.extract {inherit pname version src;};
          in
            appimageTools.wrapType2 {
              inherit pname version src;

              extraInstallCommands = ''
                install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
                substituteInPlace $out/share/applications/${pname}.desktop \
                  --replace 'Exec=AppRun' 'Exec=${pname}'
                cp -r ${appimageContents}/usr/share/icons $out/share
              '';
            })

          (pkgs.writeShellScriptBin "magicavoxel" ''
            ${pkgs.wine64Packages.unstable}/bin/wine64 ${inputs.magicavoxel}/MagicaVoxel.exe
          '')
          pkgs.wine64Packages.unstable
          pkgs.winePackages.unstable
        ];
      };
    });
}
