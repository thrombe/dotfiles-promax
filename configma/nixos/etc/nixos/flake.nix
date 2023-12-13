{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nix-index-database.follows = "nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };

    helix-git = {
      url = "github:helix-editor/helix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-update-input = {
      url = "github:vimjoyer/nix-update-input";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    configma = {
      url = "github:thrombe/configma";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    yankpass = {
      url = "github:thrombe/yankpass/discord_abuse";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    scripts = {
      url = "github:thrombe/dotfiles-promax?dir=scripts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs: let
    system = "x86_64-linux";
    username = "issac";

    # helpers
    flakeDefaultPackage = flake: flake.packages."${system}".default;
    getScript = name: inputs.scripts.packages."${system}"."${name}";

    overlay-unstable = final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        overlay-unstable
        inputs.nix-alien.overlays.default
        (self: super: {
          helix = flakeDefaultPackage inputs.helix-git;
          asusctl = super.unstable.asusctl;
          tlp = super.unstable.tlp;
          # disable shell completion for dust (completion does not work for me)
          # - [du-dust nixpkgs](https://github.com/NixOS/nixpkgs/blob/aeefe2054617cae501809b82b44a8e8f7be7cc4b/pkgs/tools/misc/dust/default.nix#L27C1-L27C14)
          du-dust = super.du-dust.overrideAttrs {postInstall = "";};
        })
      ];
    };

    # - [Future of Bismuth after kde 5.27](https://github.com/Bismuth-Forge/bismuth/issues/471#issuecomment-1700307974)
    # or try this new project:
    #   - [GitHub - zeroxoneafour/polonium: Tiling window manager for KWin 5.27](https://github.com/zeroxoneafour/polonium)
    bismuth =
      pkgs.libsForQt5.bismuth.overrideAttrs
      (finalAttrs: previousAttrs: {
        patches =
          (previousAttrs.patches or [])
          ++ [
            # (fetchpatch {
            #   name = "bismuth-3.1-4-border-color.patch";
            #   url = "https://github.com/I-Want-ToBelieve/bismuth/commit/dac110934fe1ae0da9e4aca8c331f27987b033cf.patch";
            #   sha256 = "sha256-3fQs/A4hc/qeiu+792nZBTl4ujg8rQD25kuwNr03YUs=";
            # })
            (pkgs.fetchpatch {
              name = "bismuth-3.1-4-static-block.patch";
              url = "https://github.com/I-Want-ToBelieve/bismuth/commit/99438b55a82f90d4df3653d00f1f0978eddc2725.patch";
              sha256 = "sha256-jEt0YdS7k0bJRIS0UMY21o71jgrJcwNp3gFA8e8TG6I=";
            })
            (pkgs.fetchpatch {
              name = "bismuth-3.1-4-window-id.patch";
              url = "https://github.com/jkcdarunday/bismuth/commit/ce377a33232b7eac80e7d99cb795962a057643ae.patch";
              sha256 = "sha256-15txf7pRhIvqsrBdBQOH1JDQGim2Kh5kifxQzVs5Zm0=";
            })
          ];
      });

    commonModules = [
      # {_module.args = inputs;}
      ./configuration.nix
      inputs.nix-index-database.nixosModules.nix-index

      ({...}: {
        users.users."${username}".packages =
          (map flakeDefaultPackage (with inputs; [
            # - [install a flake package](https://discourse.nixos.org/t/how-to-install-a-python-flake-package-via-configuration-nix/26970/2)
            configma
            yankpass
            nix-update-input # update-input
          ]))
          ++ (map getScript [
            "wait-until"
          ])
          ++ [
            bismuth
          ];
      })

      # - [Home Manager Manual](https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module)
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
        };
        # home-manager.users."${username}" = import ./home.nix;
        home-manager.users."${username}" = {...}: {
          home.username = "${username}";
          home.homeDirectory = "/home/${username}";
          home.stateVersion = "23.05";

          home.packages = [];
        };
      }

      # - [Nixos and Hyprland - Best Match Ever - YouTube](https://www.youtube.com/watch?v=61wGzIv12Ds)
      # - [Installing NixOS with Hyprland! - by Josiah - Tech Prose](https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland)
      ({...}: {
        programs.hyprland = {
          enable = true;
          enableNvidiaPatches = true;
          xwayland.enable = true;
        };

        environment.sessionVariables = {
          # if cursor invisible
          WLR_NO_HARDWARE_CURSORS = "1";

          # hint electron to use wayland
          NIXOS_OZONE_WL = "1";
        };
        # hardware.nvidia.modsetting.enable = true;

        environment.systemPackages = with pkgs; [
          # eww
          (pkgs.waybar.overrideAttrs (old: {
            mesonFlags = old.mesonFlags ++ ["-Dexperimental=true"];
          }))
          dunst
          libnotify
          swww
          kitty
          rofi-wayland
          networkmanagerapplet

          # xrandr eq for wl-roots compositors
          wlr-randr
          wl-clipboard
        ];

        xdg.portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = [pkgs.xdg-desktop-portal-gtk];
        };

        fonts.packages = with pkgs; [
          nerdfonts
          meslo-lgs-nf
        ];
      })
    ];
  in {
    nixosConfigurations = {
      ga402xu = inputs.nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "ga402xu";
          inherit pkgs system username;
        };

        modules =
          commonModules
          ++ [
            ./${specialArgs.hostname}/configuration.nix
            inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402
          ];
      };
    };
  };
}
