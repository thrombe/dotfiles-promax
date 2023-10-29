{ stdenv, autoPatchelfHook, fetchzip, lib, makeWrapper }:

let
  pkgs = import <nixpkgs> { };
in stdenv.mkDerivation
rec {
  name = "ultimmc";
  system = "x86_64-linux";
  src = fetchzip {
    # - [GitHub - UltimMC/Launcher](https://github.com/UltimMC/Launcher)
    url = "https://nightly.link/UltimMC/Launcher/workflows/main/develop/mmc-cracked-lin64.zip";
    # sha256 = lib.fakeSha256;
    sha256 = "sha256-BLapaqOl8DYNxXGMfSYOC1PvuUYzVpnIMFvxQBCpU6w=";
  };

  nativeBuildInputs = with pkgs; [
    # - [run a non-nixos executable on Nixos](https://unix.stackexchange.com/questions/522822/different-methods-to-run-a-non-nixos-executable-on-nixos)
    autoPatchelfHook

    # - [Qt - NixOS Wiki](https://nixos.wiki/wiki/Qt)
    libsForQt5.qt5.wrapQtAppsHook
    # libsForQt5.qt5.qtbase
    # libsForQt5.qt5.qttools

    # libpulseaudio
    # libGL
    # openal
    makeWrapper
  ];

  # libpath = lib.makeLibraryPath (with pkgs; [
  #   libpulseaudio
  #   libGL
  #   openal
  #   xorg.libXcursor
  #   xorg.libXrandr
  #   xorg.libXxf86vm # Needed only for versions <1.13
  # ]);

  # buildInputs = with pkgs; [
  # ];

  installPhase = ''
    mkdir -p $out
    cp -r bin $out/bin

    # cp UltimMC $out/bin/.
    # chmod +x $out/bin/UltimMC

    mv $out/bin/UltimMC $out/bin/${name}
    chmod +x $out/bin/${name}

    # echo "exec $out/bin/bin/UltimMC -d \$HOME/.config/${name} \$@" > $out/bin/${name}
    # chmod +x $out/bin/${name}

    # - [How to package my software in nix](https://unix.stackexchange.com/questions/717168/how-to-package-my-software-in-nix-or-write-my-own-package-derivation-for-nixpkgs)
    # - [nixpkgs/pkgs/build-support/setup-hooks/make-wrapper.sh](https://github.com/NixOS/nixpkgs/blob/71aababc6a707f9cbd1eb0a80524dfe95677e991/pkgs/build-support/setup-hooks/make-wrapper.sh#L208)
    # - [prismlauncher: OpenAL fails to initialize, no audio in-game](https://github.com/NixOS/nixpkgs/issues/206378)
    wrapProgram $out/bin/${name} \
      --prefix PATH : ${lib.makeBinPath [ pkgs.alsa-oss pkgs.jdk ]} \
      --add-flags "-d \$HOME/.config/${name}"
  '';
}
