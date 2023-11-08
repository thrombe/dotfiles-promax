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
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        # config.cudaSupport = true;

        # - [github ollama](https://github.com/jmorganca/ollama)
        # - [github llama.cpp](https://github.com/ggerganov/llama.cpp)
        # - [ollama cuda out of vram](https://github.com/jmorganca/ollama/issues/797)

        overlays = [
          (self: super: {
            llama-cpp = super.llama-cpp.override {
              cudaSupport = true;
              openblasSupport = false;
            };
          })
        ];
      };

      # - [nixpkgs llama-cpp](https://github.com/NixOS/nixpkgs/blob/85f1ba3e51676fa8cc604a3d863d729026a6b8eb/pkgs/by-name/ll/llama-cpp/package.nix#L122)
      llama-cpp-handroll = unstable.callPackage ({
        lib,
        cmake,
        darwin,
        fetchFromGitHub,
        nix-update-script,
        stdenv,
        symlinkJoin,
        config,
        cudaSupport ? config.cudaSupport,
        cudaPackages ? {},
        rocmSupport ? false,
        rocmPackages ? {},
        openclSupport ? false,
        clblast,
        openblasSupport ? true,
        openblas,
        pkg-config,
      }: let
        cudatoolkit_joined = symlinkJoin {
          name = "${cudaPackages.cudatoolkit.name}-merged";
          paths =
            [
              cudaPackages.cudatoolkit.lib
              cudaPackages.cudatoolkit.out
            ]
            ++ lib.optionals (lib.versionOlder cudaPackages.cudatoolkit.version "11") [
              # for some reason some of the required libs are in the targets/x86_64-linux
              # directory; not sure why but this works around it
              "${cudaPackages.cudatoolkit}/targets/${stdenv.system}"
            ];
        };
        metalSupport = stdenv.isDarwin && stdenv.isAarch64;
      in
        stdenv.mkDerivation (finalAttrs: {
          pname = "llama-cpp";
          # version = "1469";
          version = "1499";

          src = fetchFromGitHub {
            owner = "ggerganov";
            repo = "llama.cpp";
            rev = "refs/tags/b${finalAttrs.version}";
            # hash = "sha256-budBvpX2SnKekGTWHomvhW+4grB8EPd9OJbufNynHsc=";
            hash = "sha256-Va/3LCz+4Jl4fwOmUglVCJeIwBiTQqmvpOH75kftBbg=";
          };

          postPatch = ''
            substituteInPlace ./ggml-metal.m \
              --replace '[bundle pathForResource:@"ggml-metal" ofType:@"metal"];' "@\"$out/bin/ggml-metal.metal\";"
          '';

          nativeBuildInputs = [cmake pkg-config];

          buildInputs =
            lib.optionals metalSupport
            (with darwin.apple_sdk.frameworks; [
              Accelerate
              CoreGraphics
              CoreVideo
              Foundation
              MetalKit
            ])
            ++ lib.optionals cudaSupport [
              cudatoolkit_joined
            ]
            ++ lib.optionals rocmSupport [
              rocmPackages.clr
              rocmPackages.hipblas
              rocmPackages.rocblas
            ]
            ++ lib.optionals openclSupport [
              clblast
            ]
            ++ lib.optionals openblasSupport [
              openblas
            ];

          cmakeFlags =
            [
              "-DLLAMA_NATIVE=OFF"
              "-DLLAMA_BUILD_SERVER=ON"
            ]
            ++ lib.optionals metalSupport [
              "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
              "-DLLAMA_METAL=ON"
            ]
            ++ lib.optionals cudaSupport [
              "-DLLAMA_CUBLAS=ON"
            ]
            ++ lib.optionals rocmSupport [
              "-DLLAMA_HIPBLAS=1"
              "-DCMAKE_C_COMPILER=hipcc"
              "-DCMAKE_CXX_COMPILER=hipcc"
              "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
            ]
            ++ lib.optionals openclSupport [
              "-DLLAMA_CLBLAST=ON"
            ]
            ++ lib.optionals openblasSupport [
              "-DLLAMA_BLAS=ON"
              "-DLLAMA_BLAS_VENDOR=OpenBLAS"
            ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin

            for f in bin/*; do
              test -x "$f" || continue
              cp "$f" $out/bin/llama-cpp-"$(basename "$f")"
            done

            ${lib.optionalString metalSupport "cp ./bin/ggml-metal.metal $out/bin/ggml-metal.metal"}

            runHook postInstall
          '';

          passthru.updateScript = nix-update-script {
            attrPath = "llama-cpp";
            extraArgs = ["--version-regex" "b(.*)"];
          };
        })) {
        openblasSupport = false;
        cudaSupport = true;
      };

      # - [nixpkgs ollama](https://github.com/NixOS/nixpkgs/blob/85f1ba3e51676fa8cc604a3d863d729026a6b8eb/pkgs/tools/misc/ollama/default.nix)
      ollama-handroll =
        pkgs.buildGoModule
        rec {
          pname = "ollama";
          # version = "0.1.7";
          version = "0.1.8";

          src = pkgs.fetchFromGitHub {
            owner = "jmorganca";
            repo = "ollama";
            rev = "v${version}";
            # hash = "sha256-rzcuRU2qcYTMo/GxiSHwJYnvA9samfWlztMEhOGzbRg=";
            hash = "sha256-cHkuCRdxHxNGlgPWnUeVPeW/75C0dHEbVQ3sb1uq6xo=";
          };
          # vendorHash = "sha256-Qt5QVqRkwK61BJPVhFWtox6b9E8BpAIseNB0yhh+/90=";
          vendorHash = "sha256-NrRj+YmsNgehxgPL/fzG4sH1CCt42KMkhpNyifiyDWM=";

          buildInputs = with pkgs; [
            pkg-config
            cudatoolkit
            cmake
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
            cudatoolkit
            cmake
          ];

          patches = [
            # disable passing the deprecated gqa flag to llama-cpp-server
            # see https://github.com/ggerganov/llama.cpp/issues/2975
            ./disable-gqa.patch

            # replace the call to the bundled llama-cpp-server with the one in the llama-cpp package
            ./set-llamacpp-path.patch
          ];

          postPatch = ''
            substituteInPlace llm/llama.go \
              --subst-var-by llamaCppServer "${llama-cpp-handroll}/bin/llama-cpp-server"
          '';

          ldflags = [
            "-s"
            "-w"
            "-X=github.com/jmorganca/ollama/version.Version=${version}"
            "-X=github.com/jmorganca/ollama/server.mode=release"
          ];
        };
    in {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          # llama-cpp-handroll
          # unstable.ollama
          ollama-handroll

          # pkg-config
          # cudatoolkit
          # cmake
          # addOpenGLRunpath
        ];
      };
    });
}
