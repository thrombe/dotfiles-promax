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

      fhs = pkgs.buildFHSEnv {
        name = "fhs-shell";
        targetPkgs = p: (packages p) ++ [fooocus-serve];
        runScript = "${pkgs.zsh}/bin/zsh";
        profile = ''
          export FHS=1
          source ./.venv/bin/activate
        '';
      };
      fooocus-serve = 
        (pkgs.buildFHSEnv {
          name = "fooocus-serve";
          targetPkgs = packages;
          runScript = ''
            #!/usr/bin/env bash
            source ./.venv/bin/activate
            # pip install -r ./Fooocus/requirements_versions.txt
            python ./Fooocus/entry_with_update.py
          '';
        });
      comfyui-serve = 
        (pkgs.buildFHSEnv {
          name = "comfyui-serve";
          targetPkgs = packages;
          runScript = ''
            #!/usr/bin/env bash
            source ./.venv/bin/activate
            python ./ComfyUI/main.py
          '';
        });
      sd-webui-serve = 
        (pkgs.buildFHSEnv {
          name = "sd-webui-serve";
          targetPkgs = packages;
          runScript = ''
            #!/usr/bin/env bash
            source ./.venv/bin/activate
            python ./stable-diffusion-webui/webui.py
          '';
        });
      textg-webui-serve = 
        (pkgs.buildFHSEnv {
          name = "textg-webui-serve";
          targetPkgs = packages;
          runScript = ''
            #!/usr/bin/env bash
            sh ./text-generation-webui/start_linux.sh
          '';
        });

      packages = pkgs: (with pkgs; [
        (pkgs.python310.withPackages (ps:
          with ps; [
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
        glib

        # virtualenv .venv
        # source ./.venv/bin/activate
        # pip install ..
        # python311Packages.venvShellHook # ??
      ]);
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [fhs fooocus-serve comfyui-serve sd-webui-serve textg-webui-serve] ++ packages pkgs;
      };
      # devShells.default = fhs.env;
    });
}
