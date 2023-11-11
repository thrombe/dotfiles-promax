{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    onedriver-git = {
      url = "https://github.com/jstaf/onedriver";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    ...
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

      onedriver-handroll = {
        buildGoModule,
        fetchFromGitHub,
        lib,
        pkg-config,
        webkitgtk_4_1,
        glib,
        fuse,
        installShellFiles,
      }: let
        # - [nixpkgs onedriver](https://github.com/NixOS/nixpkgs/blob/85f1ba3e51676fa8cc604a3d863d729026a6b8eb/pkgs/by-name/on/onedriver/package.nix#L52)
        pname = "onedriver";
        version = "0.14.1";
        # version = "0.13.0-2";

        # src = inputs.onedriver-git;
        src = fetchFromGitHub {
          owner = "jstaf";
          repo = "onedriver";
          rev = "v${version}";
          # hash = "sha256-Bcjgmx9a4pTRhkzR3tbOB6InjvuH71qomv4t+nRNc+w=";
          hash = "sha256-mA5otgqXQAw2UYUOJaC1zyJuzEu2OS/pxmjJnWsVdxs=";
        };
      in
        buildGoModule {
          inherit pname version src;

          vendorHash = "sha256-OOiiKtKb+BiFkoSBUQQfqm4dMfDW3Is+30Kwcdg8LNA=";

          doCheck = false;

          nativeBuildInputs = [pkg-config installShellFiles];
          buildInputs = [webkitgtk_4_1 glib fuse];

          ldflags = ["-X github.com/jstaf/onedriver/cmd/common.commit=v${version}"];

          subPackages = [
            "cmd/onedriver"
            "cmd/onedriver-launcher"
          ];

          postInstall = ''
            echo "Running postInstall"
            # install -Dm644 ./resources/onedriver.svg $out/share/icons/onedriver/onedriver.svg
            # install -Dm644 ./resources/onedriver.png $out/share/icons/onedriver/onedriver.png
            # install -Dm644 ./resources/onedriver-128.png $out/share/icons/onedriver/onedriver-128.png

            # install -Dm644 ./resources/onedriver.desktop $out/share/applications/onedriver.desktop

            # mkdir -p $out/share/man/man1
            # installManPage ./resources/onedriver.1

            # substituteInPlace $out/share/applications/onedriver.desktop \
            #   --replace "/usr/bin/onedriver-launcher" "$out/bin/onedriver-launcher" \
            #   --replace "/usr/share/icons" "$out/share/icons"
          '';
        };
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          (pkgs.callPackage onedriver-handroll {})
        ];
      };
    });
}
