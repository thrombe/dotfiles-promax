{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      config = {
        allowUnfree = true;
        # cudaSupport = true;
      };

      overlay-unstable = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system config;
        };
      };
      pkgs = import inputs.nixpkgs {
        inherit system config;
        overlays = [
          overlay-unstable
          (self: super: {})
        ];
      };

      dontCheckPython = drv: drv.overridePythonAttrs (old: {doCheck = false;});

      packages = pkgs: (with pkgs; [
        pkgs.stdenv.cc.cc.lib

        # (python3.withPackages (ps:
        #   with ps; [
        #     (dontCheckPython numpy)
        #     (dontCheckPython torch)
        #     (dontCheckPython torchvision)
        #   ]))
        # python3Packages.pip
        # python3Packages.virtualenv
        (pkgs.python310.withPackages (ps:
          with ps; [
            # numpy
            # torch-bin
            # torchsde
            # torchvision-bin
            # gradio
            # einops
            # transformers
            # safetensors
            # accelerate
            # pyyaml
            # pillow
            # scipy
            # tqdm
            # psutil
            # # pytorch_lightning
            # omegaconf
            # pygit2
            # # opencv-contrib-python
            # httpx
          ]))
        pkgs.python310Packages.pip
        pkgs.python310Packages.virtualenv
        zlib

        pkg-config
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libxcb
        libGL
        vulkan-headers
        vulkan-loader
        libxkbcommon
        glibc
        glib

        # python311Packages.python-lsp-server
        # python311Packages.ruff-lsp # python linter
        # python311Packages.black # python formatter
        # unstable.pyenv # kinda like 'nvm' but python
        # virtualenv .venv
        # source ./.venv/bin/activate
        # pip install ..
        # python311Packages.venvShellHook
        # python311Packages.torch

        # vscodium-fhs
        # (vscode-with-extensions.override {
        #   vscode = vscodium;
        #   vscodeExtensions = with vscode-extensions;
        #     [
        #       # bbenoist.nix
        #       ms-python.python
        #       # ms-python.vscode-pylance
        #       # ms-vscode-remote.remote-ssh
        #       ms-toolsai.jupyter
        #     ]
        #     ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        #       # {
        #       #   name = "remote-ssh-edit";
        #       #   publisher = "ms-vscode-remote";
        #       #   version = "0.47.2";
        #       #   sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        #       # }
        #     ];
        # })
      ]);
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs =
          (packages pkgs)
          ++ [
            (pkgs.buildFHSEnv {
              name = "fhs-run";
              targetPkgs = packages;
              runScript = ''
                #!/usr/bin/env bash
                source ./.venv/bin/activate
                # cd ./Fooocus
                # pip install -r ./requirements_versions.txt
                # python ./entry_with_update.py
                python ./Fooocus/entry_with_update.py
              '';
            })
            (pkgs.buildFHSUserEnv {
              name = "fhs-shell";
              targetPkgs = packages;
              runScript = "${pkgs.zsh}/bin/zsh";
              profile = ''
                source ./.venv/bin/activate
              '';
            })
          ];
        shellHook = ''
          # source ./.venv/bin/activate
          LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
        '';
      };
      devShells.fhs =
        (pkgs.buildFHSUserEnv {
          name = "fhs-shell";
          targetPkgs = packages;
          runScript = "${pkgs.zsh}/bin/zsh";
        })
        .env;
    });
}
