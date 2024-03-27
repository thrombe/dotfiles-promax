{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-git.url = "github:nixos/nixpkgs";

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
      # inputs.flake-utils.follows = "flake-utils";
      # inputs.crane = {
      #   url = "github:ipetkov/crane";
      #   inputs.flake-compat.follows = "flake-compat";
      # };
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
    hyprkool = {
      url = "github:thrombe/hyprkool/dev";
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
      pkgs-git = import inputs.nixpkgs-git {
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

          # - [asusctl: 4.7.2 -> 5.0.0, supergfxctl: 5.1.1 -> 5.1.2](https://github.com/NixOS/nixpkgs/pull/273808/files)
          asusctl = super.unstable.asusctl;
          supergfxctl = super.unstable.supergfxctl;

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
            hyprkool
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
        home-manager.users."${username}" = {config, ...}: {
          home.username = "${username}";
          home.homeDirectory = "/home/${username}";
          home.stateVersion = "23.05";

          # - [cursors home-manager options](https://nix-community.github.io/home-manager/options.xhtml#opt-home.pointerCursor)
          # TODO: still broken
          # possible fixes:
          #   - [Hyprcursor | Hyprland Wiki](https://wiki.hyprland.org/Hypr-Ecosystem/hyprcursor/#important-notes)
          #   - [Master Tutorial | Hyprland Wiki](https://wiki.hyprland.org/Getting-Started/Master-Tutorial/#themes)
          #   - [Cursor themes - ArchWiki](https://wiki.archlinux.org/title/Cursor_themes)
          home.pointerCursor = {
            x11.enable = true;
            gtk.enable = true;
            size = 48;

            package = pkgs.phinger-cursors;
            name = "phinger-cursors-light";

            # package = pkgs.catppuccin-cursors;
            # name = "capitaine-cursors";

            # package = pkgs.volantes-cursors;
            # name = "volantes_light_cursors";
            # name = "volantes_cursors";

            # package = pkgs.vimix-cursors;
            # name = "Vimix-white-cursors";
            # name = "Vimix-cursors";
          };

          home.packages = [];

          # - [Nushell - NixOS Wiki](https://nixos.wiki/wiki/Nushell)
          programs = {
            nushell = {
              enable = true;
              # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
              # configFile.source = ./.../config.nu;
              # for editing directly to config.nu
              extraConfig = ''
                let carapace_completer = {|spans|
                  carapace $spans.0 nushell $spans | from json
                }
                $env.config = {
                 show_banner: false,
                 completions: {
                   case_sensitive: false # case-sensitive completions
                   quick: true    # set to false to prevent auto-selecting completions
                   partial: true    # set to false to prevent partial filling of the prompt
                   algorithm: "fuzzy"    # prefix or fuzzy
                   external: {
                       # set to false to prevent nushell looking into $env.PATH to find more suggestions
                       enable: true
                       # set to lower can improve completion performance at the cost of omitting some options
                       max_results: 100
                       completer: $carapace_completer # check 'carapace_completer'
                     }
                   }

                  keybindings: [
                    # still no fzf tab :(
                    # - [Fuzzy Completion Option for nushell · Issue #1275 · nushell/nushell · GitHub](https://github.com/nushell/nushell/issues/1275)
                    # - [History (ctrl + r) with fzf](https://github.com/nushell/nushell/issues/1616#issuecomment-1386714173)
                    {
                      name: fuzzy_history
                      modifier: control
                      keycode: char_r
                      mode: [emacs, vi_normal, vi_insert]
                      event: [
                        {
                          send: ExecuteHostCommand
                          cmd: "commandline (
                            history
                              | each { |it| $it.command }
                              | uniq
                              | reverse
                              | str join (char -i 0)
                              | fzf --read0 --layout=reverse --height=40% -q (commandline)
                              | decode utf-8
                              | str trim
                          )"
                        }
                      ]
                    }
                  ]
                }

                $env.PATH = ($env.PATH |
                  split row (char esep) |
                  prepend /home/myuser/.apps |
                  append /usr/bin/env
                )

                use ~/.cache/starship/init.nu
                # - [starship.nix](https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/programs/starship.nix)
                # $env.STARSHIP_CONFIG = ${(pkgs.formats.toml {}).generate "starship.toml" config.programs.starship.settings}
                $env.STARSHIP_CONFIG = ${(pkgs.formats.toml {}).generate "starship.toml" (import ./starship.nix {})}

                source ~/.cache/nushell/zoxide.nu
              '';
              extraEnv = ''
                mkdir ~/.cache/starship
                starship init nu | save -f ~/.cache/starship/init.nu

                mkdir ~/.cache/nushell
                zoxide init nushell | save -f ~/.cache/nushell/zoxide.nu
              '';
              shellAliases = {
              };
            };
            carapace.enable = true;
            carapace.enableNushellIntegration = true;
          };
        };
      }

      # - [Nixos and Hyprland - Best Match Ever - YouTube](https://www.youtube.com/watch?v=61wGzIv12Ds)
      # - [Installing NixOS with Hyprland! - by Josiah - Tech Prose](https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland)
      ({...}: {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          package = pkgs.unstable.hyprland;
        };

        environment.sessionVariables = {
          # if cursor invisible
          WLR_NO_HARDWARE_CURSORS = "1";

          # hint electron to use wayland
          NIXOS_OZONE_WL = "1";
        };
        # hardware.nvidia.modsetting.enable = true;

        environment.systemPackages = with pkgs; [
          dunst
          libnotify
          networkmanagerapplet
          brightnessctl

          # widget/bar
          unstable.eww
          (pkgs.unstable.waybar.overrideAttrs (old: {
            mesonFlags = old.mesonFlags ++ ["-Dexperimental=true"];
          }))

          # app launcher
          rofi-wayland

          # wallpaper stuff
          swww

          # xrandr eq for wl-roots compositors
          wlr-randr
          wl-clipboard
          cliphist
          wtype

          # plugin manager
          unstable.pyprland
          # plugins
          # unstable.hyprcursor
          unstable.hyprlock
          unstable.hypridle
          unstable.hyprshot

          (pkgs.writeShellScriptBin "start-hypr" ''
            export XDG_SESSION_TYPE=wayland

            ${pkgs.hyprland}/bin/Hyprland
          '')
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
            inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x.nvidia
          ];
      };
    };
  };
}
