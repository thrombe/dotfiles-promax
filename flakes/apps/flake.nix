{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable2.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable3.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rio = {
      url = "github:raphamorim/rio";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    alacritty = {
      url = "github:ayosec/alacritty/graphics";
      flake = false;
    };
    zellij = {
      url = "github:lypanov/zellij/repeat_instruction_retries";
      flake = false;
    };

    magicavoxel = {
      url = "https://github.com/ephtracy/ephtracy.github.io/releases/download/0.99.7/MagicaVoxel-0.99.7.1-win64.zip";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      flakePackage = flake: package: flake.packages."${system}"."${package}";
      flakeDefaultPackage = flake: flakePackage flake "default";

      overlay-unstable = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          config.cudaSupport = true;
        };
        unstable3 = import inputs.nixpkgs-unstable3 {
          inherit system;
        };
        unstable-nocuda = import inputs.nixpkgs-unstable {
          inherit system;
        };
        unstable-nocuda2 = import inputs.nixpkgs-unstable2 {
          inherit system;
          config.allowUnfree = true;
        };
      };
      overlays = self: super: {
        inherit focalboard focalboard-server moosync muffon cursor record-this-window magicavoxel;

        # - [zsh with glyphs won't render](https://github.com/raphamorim/rio/issues/499)
        rio = flakeDefaultPackage inputs.rio;
        opera = super.opera.override {proprietaryCodecs = true;};
        rustdesk-flutter = super.symlinkJoin {
          name = "rustdesk";
          paths = [super.unstable-nocuda2.rustdesk-flutter];
          buildInputs = [super.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/rustdesk --set GDK_BACKEND x11
          '';
        };

        blender = super.unstable.blender;
        godot_4 = super.unstable.godot_4;
        logseq = super.unstable.logseq;
        obsidian = super.unstable.obsidian;
        nuclear = super.unstable.nuclear;
        floorp = super.unstable.floorp;
        slurp = super.unstable.slurp;
        wf-recorder = super.unstable.wf-recorder;

        obs-studio = super.unstable-nocuda.obs-studio;

        anydesk = super.unstable-nocuda2.anydesk;
        krita = super.unstable-nocuda2.krita;
        kdenlive = super.unstable-nocuda2.libsForQt5.kdenlive;

        zed-editor = super.unstable3.zed-editor;
      };

      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
        overlays = [
          overlay-unstable
          overlays
        ];
      };

      focalboard = pkgs.stdenv.mkDerivation {
        name = "focalboard";
        src = pkgs.fetchurl {
          url = "https://github.com/mattermost/focalboard/releases/download/v7.10.6/focalboard-linux.tar.gz";
          hash = "sha256-Z3fxbfqh3uAUKhbRnOL7JLDL4CBsSAR+EuLly54CEA8=";
        };

        installPhase = ''
          mkdir -p $out/bin

          cd $out
          tar -xvzf $src -C $out/.
          mv $out/focalboard-app/* $out/bin
          rmdir $out/focalboard-app

          # it looks for db at ./focalboard.db anyway
          echo "
              {
              	"serverRoot": "http://localhost:8088",
              	"port": 8088,
              	"dbtype": "sqlite3",
              	"dbconfig": "/home/issac/.config/focalboard/focalboard.db",
              	"useSSL": false,
              	"webpath": "$out/bin/pack",
              	"filespath": "/home/issac/.config/focalboard/files",
              	"telemetry": false,
              	"localOnly": true
              }
          " > $out/bin/config.json
        '';

        nativeBuildInputs = with pkgs; [pkg-config installShellFiles pkgs.autoPatchelfHook];
        buildInputs = with pkgs; [gtk3 webkitgtk go nodejs_20];
      };
      focalboard-server = pkgs.stdenv.mkDerivation {
        name = "focalboard";
        src = pkgs.fetchurl {
          url = "https://github.com/mattermost/focalboard/releases/download/v7.10.6/focalboard-server-linux-amd64.tar.gz";
          hash = "sha256-dkdMQcF/aTrHMDyJgV9RAB0KzC1ehEvKmEYCkHkDi/4=";
        };

        installPhase = ''
          mkdir -p $out/bin

          cd $out
          tar -xvzf $src -C $out/.
          mv $out/focalboard/bin/* $out/bin/.
          mv $out/focalboard/pack $out/bin/.
          # rmdir $out/focalboard-app

          echo "
              {
              	\"serverRoot\": \"http://localhost:8088\",
              	\"port\": 8088,
              	\"dbtype\": \"sqlite3\",
              	\"dbconfig\": \"/home/issac/.local/share/focalboard/focalboard.db\",
                \"postgres_dbconfig\": \"dbname=focalboard sslmode=disable\",
              	\"useSSL\": false,
              	\"webpath\": \"$out/bin/pack\",
              	\"filespath\": \"/home/issac/.local/share/focalboard/files\",
                \"prometheusaddress\": \":9092\",
                \"session_expire_time\": 2592000,
                \"session_refresh_time\": 18000,
              	\"telemetry\": false,
                \"enableLocalMode\": true,
                \"localModeSocketLocation\": \"/var/tmp/focalboard_local.socket\",
              	\"localOnly\": true
              }
          " > $out/bin/config.json
        '';

        nativeBuildInputs = with pkgs; [pkg-config installShellFiles pkgs.autoPatchelfHook];
        buildInputs = with pkgs; [gtk3 webkitgtk go nodejs_20];
      };
      record-this-window = pkgs.writeShellScriptBin "record-this-window" ''
        monitors=`hyprctl -j monitors`
        clients=`hyprctl -j clients | jq -r '[.[] | select(.workspace.id | contains('$(echo $monitors | jq -r 'map(.activeWorkspace.id) | join(",")')'))]'`
        boxes="$(echo $clients | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"')"
        geometry="$(slurp -r <<< "$boxes")"
        echo $geometry
        wf-recorder -g "$geometry" $@
      '';
      magicavoxel = pkgs.writeShellScriptBin "magicavoxel" ''
        ${pkgs.wine64Packages.unstable}/bin/wine64 ${inputs.magicavoxel}/MagicaVoxel.exe
      '';
      moosync = let
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
        };
      muffon = let
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
        };
      cursor = let
        pname = "cursor";
        version = "0.40";

        src = pkgs.fetchurl {
          # this will break if the version is updated.
          # unfortunately, i couldn't seem to find a url that
          # points to a specific version.
          # alternatively, download the appimage manually and
          # include it via src = ./cursor.AppImage, instead of fetchurl
          url = "https://downloader.cursor.sh/linux/appImage/x64";
          hash = "sha256-ZURE8UoLPw+Qo1e4xuwXgc+JSwGrgb/6nfIGXMacmSg=";
        };
        appimageContents = pkgs.appimageTools.extract {inherit pname version src;};
      in
        with pkgs;
          appimageTools.wrapType2 {
            inherit pname version src;
            extraInstallCommands = ''
              install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
              substituteInPlace $out/share/applications/${pname}.desktop \
                --replace 'Exec=AppRun' 'Exec=${pname}'
              cp -r ${appimageContents}/usr/share/icons $out/share

              # unless linked, the binary is placed in $out/bin/cursor-someVersion
              # ln -s $out/bin/${pname}-${version} $out/bin/${pname}
            '';

            extraBwrapArgs = [
              "--bind-try /etc/nixos/ /etc/nixos/"
            ];

            # vscode likes to kill the parent so that the
            # gui application isn't attached to the terminal session
            dieWithParent = false;

            extraPkgs = pkgs: [
              unzip
              autoPatchelfHook
              asar
              # override doesn't preserve splicing https://github.com/NixOS/nixpkgs/issues/132651
              (buildPackages.wrapGAppsHook.override {inherit (buildPackages) makeWrapper;})
            ];
          };

      fhs = pkgs.buildFHSEnv {
        name = "fhs-shell";
        targetPkgs = p: (env-packages p);
        runScript = "${pkgs.zsh}/bin/zsh";
        profile = ''
          export FHS=1
          # source ./.venv/bin/activate
          # source .env
        '';
      };
      env-packages = pkgs:
        with pkgs; [
          (pkgs.python310.withPackages (ps:
            with ps; [
            ]))
          pkgs.python310Packages.pip
          pkgs.python310Packages.virtualenv
          # virtualenv .venv
          # source ./.venv/bin/activate
          # pip install ..
          # python311Packages.venvShellHook # ??

          # xfce.thunar
          # cinnamon.nemo-with-extensions

          zed-editor
          cursor

          # rustdesk-flutter
          # anydesk
          remmina

          ngrok

          # logseq
          # obsidian
          # focalboard
          # focalboard-server

          obs-studio
          kdenlive
          krita
          # blender
          # godot_4

          # wf-recorder
          # slurp
          # record-this-window

          # run `ventoy-web`
          ventoy

          # - [gparted cannot open display](https://www.reddit.com/r/hyprland/comments/13ri2nj/gparted_cannot_open_display/)
          # gparted
          #  - just use gparted in virt-manager lol

          floorp
          opera
          libreoffice-qt

          # music apps
          # spotube
          # clementine
          # nuclear
          # moosync
          # muffon

          # magicavoxel
          # pkgs.wine64Packages.unstable
          # pkgs.winePackages.unstable
        ];
    in {
      packages = {};
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = (env-packages pkgs) ++ [fhs];
      };
    });
}
