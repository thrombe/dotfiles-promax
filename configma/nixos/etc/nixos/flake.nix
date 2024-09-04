{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # nixpkgs-git.url = "github:nixos/nixpkgs";
    # nur.url = "github:nix-community/NUR";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nci = {
    #   url = "github:yusdacra/nix-cargo-integration";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
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
    # MAYBE: - [nixgl wrapper](https://github.com/nix-community/nixGL/issues/140#issuecomment-1950754800)
    nixgl = {
      url = "github:nix-community/nixGL";
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    stylix = {
      url = "github:danth/stylix/release-24.05";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    helix = {
      url = "github:helix-editor/helix/24.07";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.crane.follows = "crane";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    nixvim = {
      # url = "github:nix-community/nixvim/nixos-23.11";
      # inputs.nixpkgs.follows = "nixpkgs";

      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";

      inputs.devshell.follows = "devshell";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-parts.follows = "flake-parts";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.39.1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # eww-git = {
    #   url = "github:elkowar/eww";
    #   # inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    #   inputs.flake-compat.follows = "flake-compat";
    #   inputs.rust-overlay.follows = "rust-overlay";
    # };
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
      inputs.hyprland.follows = "hyprland";
    };
    zathura-images = {
      url = "github:thrombe/zathura-images";
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
    forSystem = thing: thing."${system}";
    flakePackage = flake: package: (forSystem flake.packages)."${package}";
    flakeDefaultPackage = flake: flakePackage flake "default";
    getScript = name: (forSystem inputs.scripts.packages)."${name}";

    overlay-unstable = final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      # pkgs-git = import inputs.nixpkgs-git {
      #   inherit system;
      #   config.allowUnfree = true;
      # };
    };

    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        overlay-unstable

        # inputs.nur.overlay
        # (self: super: {
        #   # - [GitHub - nix-community/NUR: Nix User Repository: User contributed nix packages [maintainer=@Mic92]](https://github.com/nix-community/NUR)
        #   # - [Packages search for NUR](https://nur.nix-community.org/documentation/)
        #   nur = import inputs.nur {
        #     # import inputs.nixpkgs again to avoid cycle
        #     nurpkgs = import inputs.nixpkgs {inherit system;};
        #   };
        # })

        inputs.nix-alien.overlays.default
        inputs.nixgl.overlay

        # zathura-images needs unstable
        (self: super: {
          zathura = super.unstable.zathura;
        })
        (forSystem inputs.zathura-images.overlays).default

        (self: super: {
          helix = flakeDefaultPackage inputs.helix;

          # hyprland = pkgs.unstable.hyprland;
          hyprland = flakeDefaultPackage inputs.hyprland;

          # eww = super.unstable.eww;
          # eww = flakeDefaultPackage inputs.eww-git;

          # - [asusctl: 4.7.2 -> 5.0.0, supergfxctl: 5.1.1 -> 5.1.2](https://github.com/NixOS/nixpkgs/pull/273808/files)
          asusctl = super.unstable.asusctl;
          supergfxctl = super.unstable.supergfxctl;

          tlp = super.unstable.tlp;

          # disable shell completion for dust (completion does not work for me)
          # - [du-dust nixpkgs](https://github.com/NixOS/nixpkgs/blob/aeefe2054617cae501809b82b44a8e8f7be7cc4b/pkgs/tools/misc/dust/default.nix#L27C1-L27C14)
          du-dust = super.du-dust.overrideAttrs {postInstall = "";};

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
        })
      ];
    };

    commonModules = [
      # {_module.args = inputs;}
      inputs.nix-index-database.nixosModules.nix-index
      inputs.stylix.nixosModules.stylix

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
            # TODO: nixgl support (pass parameters of browser command (that way, it also has firefox support))
            #     ig also change name
            "lbwopen-links"
          ])
          ++ [
            # - [Installation - nixvim docs](https://nix-community.github.io/nixvim/user-guide/install.html)
            (pkgs.callPackage ./nixvim.nix {inherit inputs system;})
          ];
      })

      # - [Home Manager Manual](https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module)
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username inputs system;
        };
        # home-manager.users."${username}" = import ./home.nix;
        home-manager.users."${username}" = {config, ...}: {
          imports = [
            ./nushell.nix
          ];

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
            size = 24;

            # package = pkgs.phinger-cursors;
            # name = "phinger-cursors-light";

            # package = pkgs.catppuccin-cursors;
            # name = "capitaine-cursors";

            # package = pkgs.volantes-cursors;
            # name = "volantes_light_cursors";
            # name = "volantes_cursors";

            # package = pkgs.vimix-cursors;
            # name = "Vimix-white-cursors";
            # name = "Vimix-cursors";
          };

          # https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#fixing-problems-with-themes
          # gtk = {
          #   enable = true;
          # };

          home.packages = [];

          # stylix hm module goofs up when kde is not running
          stylix.targets.kde.enable = false;
        };
      }
      ./firefox.nix

      ({hostname, ...}: {
        boot.supportedFilesystems = ["ntfs"];

        networking.hostName = hostname; # Define your hostname.
        # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

        # Enable networking
        networking.networkmanager.enable = true;

        # Set your time zone.
        time.timeZone = "Asia/Kolkata";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_IN";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_IN";
          LC_IDENTIFICATION = "en_IN";
          LC_MEASUREMENT = "en_IN";
          LC_MONETARY = "en_IN";
          LC_NAME = "en_IN";
          LC_NUMERIC = "en_IN";
          LC_PAPER = "en_IN";
          LC_TELEPHONE = "en_IN";
          LC_TIME = "en_IN";
        };

        # Enable CUPS to print documents.
        services.printing.enable = true;

        # Enable sound with pipewire.
        sound.enable = true;
        hardware.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          # If you want to use JACK applications, uncomment this
          #jack.enable = true;

          # use the example session manager (no others are packaged yet so this is enabled by default,
          # no need to redefine it in your config for now)
          #media-session.enable = true;
        };

        # for easyeffects and virt-manager
        # https://github.com/NixOS/nixpkgs/issues/158476#issuecomment-1031693105
        programs.dconf.enable = true;

        # - [NixOps/Virtualization - NixOS Wiki](https://nixos.wiki/wiki/NixOps/Virtualization)
        boot.kernelModules = ["kvm-amd" "kvm-intel"];

        virtualisation = {
          spiceUSBRedirection.enable = true;
          libvirtd = {
            enable = true;
            # qemu.ovmf.packages = with pkgs; [unstable.OVMFFull];
            # enable tpm
            qemu.swtpm.enable = true;
            # qemu.runAsRoot = false; # TODO: seems interesting. look into it
          };

          # - [Podman - NixOS Wiki](https://nixos.wiki/wiki/Podman)
          podman = {
            enable = true;
            # Create a `docker` alias for podman, to use it as a drop-in replacement
            dockerCompat = true;
            # Required for containers under podman-compose to be able to talk to each other.
            defaultNetwork.settings.dns_enabled = true;
          };
        };

        programs.virt-manager.enable = true;

        # - [Bluetooth - NixOS Wiki](https://nixos.wiki/wiki/Bluetooth)
        hardware.bluetooth.enable = true;
        # if DE does not have any way to pair devices
        # services.blueman.enable = true;

        nix.settings.experimental-features = ["nix-command" "flakes"];

        environment.systemPackages = with pkgs; [
          vim
          wget
          lf
          bat
          tree
          fd
          ripgrep
          ripgrep-all
          file
          du-dust
          jq

          gparted
        ];

        # - [gparted cannot open display : r/hyprland](https://www.reddit.com/r/hyprland/comments/13ri2nj/gparted_cannot_open_display/)
        programs.partition-manager.enable = true;
        programs.kdeconnect.enable = true;

        # Define a user account. Don't forget to set a password with ‘passwd’.
        users.users."${username}" = {
          isNormalUser = true;
          description = "${username}";
          extraGroups = [
            "networkmanager"
            "wheel"
            "libvirtd"
            "audio" # for pulse
          ];
          packages = with pkgs; [
            # apps
            thunderbird
            librewolf
            ungoogled-chromium
            zathura
            stremio
            # discord # TODO: make voice work
            qbittorrent
            mpv
            
            # - [Rclone](https://rclone.org/)
            # - [Use Microsoft ONEDRIVE in LINUX](https://www.youtube.com/watch?v=u_W0-HEVOyg)
            # - [rclone mount](https://rclone.org/commands/rclone_mount/)
            # - [rclone mount](https://rclone.org/commands/rclone_mount/#vfs-file-caching)
            # rclone mount --vfs-cache-mode writes --vfs-cache-max-age 3d --vfs-cache-max-size 10G onedrive:/daata /home/$USER/onedrive
            unstable.rclone

            # tools
            helix
            unstable.alacritty
            unstable.zellij
            unstable.zoxide
            unstable.yazi
            unstable.broot
            unstable.gitui
            unstable.lazygit
            unstable.delta
            # unstable.distrobox
            trashy
            starship
            ueberzugpp
            fzf
            ripdrag
            kalker
            libqalculate
            sshfs
            neofetch
            p7zip
            unoconv
            (pkgs.writeScriptBin "convert-all-to-pdf" ''
              #!/usr/bin/env zsh
              mkdir -p unconverted
              for i in ./**.(doc|ppt|xls|docx|pptx|xlsx); do
                ${unoconv}/bin/unoconv -f pdf ./$i
                mv $i ./unconverted/$i
              done
            '')

            # `top` but for io operations
            iotop
            # - [Disc usage in proc box btop](https://github.com/aristocratos/btop/issues/519)
            btop
            s-tui # fan rpm + other stuff
            # zenith-nvidia # - [zenith](https://github.com/bvaisvil/zenith)
            nvtop # gpu stats
            # bottom # battery stat + other stuff
            # battop # only battery stat

            # - [Virt-manager - NixOS Wiki](https://nixos.wiki/wiki/Virt-manager)
            virtiofsd
            qemu

            # rice
            lightly-qt

            zsh-fzf-tab
            atuin
            carapace

            # - [JackHack96/EasyEffects-Presets](https://github.com/JackHack96/EasyEffects-Presets)
            # - [Impulse Responses](https://github.com/wwmm/easyeffects/wiki/Impulse-Responses)
            easyeffects
            # - [PipeWire / Helvum · GitLab](https://gitlab.freedesktop.org/pipewire/helvum)
            # - [sound from multiple outputs](https://askubuntu.com/a/1413329)
            helvum # allows to pipe sinks into other sinks (sound out of multiple headsets)
            # jamesdsp
            # viper also needs pulseaudio package separately for some reason
            # viper still gives problems with audio
            # viper4linux-gui # does not work with pipewire
            # viper4linux
            # pulseaudio

            unstable.nh
            unstable.nvd
            unstable.nix-output-monitor
            # nix
            nil
            nixd
            alejandra # nix formatter
            nixos-option
            cached-nix-shell
            nix-tree
            nix-melt # flake.lock visualizer
            nix-alien

            nixgl.nixGLIntel
            nixgl.nixVulkanIntel
            # auto detection needs --impure so it won't work (do i need it anyway?)
            # - [nixgl with custom nvidiaVersion?](https://discourse.nixos.org/t/design-discussion-about-nixgl-opengl-cuda-opencl-wrapper-for-nix/2453#nixgl-example-4)
            #   - can't get this to work :/
            # nixgl.auto.nixGLDefault
            # nixgl.auto.nixGLNvidia
            # nixgl.auto.nixGLNvidiaBumblebee
            # pkgs.auto.nixgl.nixVulkanNvidia

            # dev
            # rustup
            libclang
            git
            gcc
            python311
          ];
          useDefaultShell = true;
        };

        programs.nix-ld.enable = true;

        programs.nix-index-database.comma.enable = true;
        # - [Prevent garbage collection of flake](https://discourse.nixos.org/t/prevent-garbage-collection-of-flake/19959)
        # - [nix-community/nix-direnv](https://github.com/nix-community/nix-direnv)
        programs.direnv.enable = true;

        programs.command-not-found.enable = false;
        programs.nix-index = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = false;
        };

        # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enable
        programs.zsh = {
          enable = true;
          syntaxHighlighting.enable = true;
          autosuggestions.enable = true;
          shellAliases = {
            la = "ls -a";
            ll = "ls -al";
          };
          interactiveShellInit = ''
            # https://discourse.nixos.org/t/etc-profiles-per-user-user/17004/2
            # /etc/set-environment
            source /etc/profiles/per-user/$USER/share/fzf-tab/fzf-tab.plugin.zsh

            export PATH="$PATH:/home/$USER/.cargo/bin"

            # https://nixos.wiki/wiki/Fzf
            # if [ -n "$ {commands[fzf-share]}" ]; then
            #   source "$(fzf-share)/key-bindings.zsh"
            #   source "$(fzf-share)/completion.zsh"
            # fi

            eval "$(direnv hook zsh)"
            # - [How to turn down verbosity? · Issue #68 · direnv/direnv · GitHub](https://github.com/direnv/direnv/issues/68)
            # - [PS1 · direnv/direnv Wiki · GitHub](https://github.com/direnv/direnv/wiki/PS1)
            # TODO: silence direnv verbose output
          '';

          # https://discourse.nixos.org/t/programs-zsh-ohmyzsh-explained/2791/2
          ohMyZsh = {
            enable = true;
            theme = "arrow";
            plugins = ["git" "fzf"];
          };
        };
        users.defaultUserShell = pkgs.zsh;
        environment.shells = with pkgs; [zsh nushell];
        # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enableCompletion
        environment.pathsToLink = ["/share/zsh"];
        environment.variables = {
          EDITOR = "${pkgs.helix}/bin/hx";
        };

        programs.starship = {
          enable = true;
          # - [Nix file starship.toml <format = "$all"> · GitHub](https://gist.github.com/s-a-c/0e44dc7766922308924812d4c019b109#file-starship-nix)
          settings = import ./starship.nix {};
        };

        stylix = {
          enable = true;

          # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
          base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
          image = ~/0Git/dotfiles-promax/flakes/ai_apps/Fooocus/outputs/2023-12-12/2023-12-12_23-08-35_8144.png;

          cursor = {
            size = 24;

            package = pkgs.phinger-cursors;
            name = "phinger-cursors-light";
          };

          opacity = {
            terminal = 0.82;
            popups = 0.82;
          };

          polarity = "dark";

          fonts = {
            sizes = {
              applications = 10;
            };
          };
        };

        # Enable the OpenSSH daemon.
        services.openssh = {
          enable = true;
          # - [nixos wiki public key auth](https://nixos.wiki/wiki/SSH_public_key_authentication)
          # 'ssh-keygen'
          # then use 'ssh-copy-id <ip>' or just
          # copy contents of ~/.ssh/id_rsa.pub from client machine on a new line in ~/.ssh/authorized_keys in host machine
          settings.PasswordAuthentication = false;
          settings.KbdInteractiveAuthentication = false;
        };

        # Enable OpenGL
        hardware.opengl = {
          enable = true;
          driSupport = true;
          driSupport32Bit = true;
        };

        # a tool to manage cpu freq, turn off cpus, create and manage profiles, etc
        # services.cpupower-gui.enable = true;

        # Some programs need SUID wrappers, can be configured further or are
        # started in user sessions.
        # programs.mtr.enable = true;
        # programs.gnupg.agent = {
        #   enable = true;
        #   enableSSHSupport = true;
        # };

        # This value determines the NixOS release from which the default
        # settings for stateful data, like file locations and database versions
        # on your system were taken. It‘s perfectly fine and recommended to leave
        # this value at the release version of the first install of this system.
        # Before changing this value read the documentation for this option
        # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
        system.stateVersion = "23.05"; # Did you read the comment?
      })

      # kde
      ({...}: {
        services.xserver = {
          # Enable the X11 windowing system.
          enable = true;

          # - ["Keyboard Layout Customization" - NixOS Wiki](https://nixos.wiki/index.php?title=Keyboard_Layout_Customization&diff=8386&oldid=8257)
          displayManager = {
            sessionCommands = "${pkgs.xorg.xmodmap}/bin/xmodmap ${pkgs.writeText "xkb-layout" ''
              ! rog key
              keycode 156 = Super_L

              ! num-enter key
              keycode 104 = Super_L

              ! num-plus key
              keycode 86 = Alt_L
            ''}";
          };

          # Configure keymap in X11
          layout = "us";
          xkbVariant = "";

          # Enable touchpad support (enabled default in most desktopManager).
          # services.xserver.libinput.enable = true;

          # Enable the KDE Plasma Desktop Environment.
          displayManager.sddm.enable = true;
          desktopManager.plasma5.enable = true;
        };

        # exclude some kde apps - [KDE - NixOS Wiki](https://nixos.wiki/wiki/KDE)
        environment.plasma5.excludePackages = with pkgs.libsForQt5; [
          # elisa
          # gwenview
          okular
          # oxygen
          # khelpcenter
          # konsole
          plasma-browser-integration
          # print-manager
        ];

        users.users."${username}" = {
          packages = with pkgs; [
            xorg.xmodmap
            xdotool
            xorg.xhost
            xclip
            wmctrl
            numlockx
            libnotify

            bismuth
          ];
        };
      })

      # - [Nixos and Hyprland - Best Match Ever - YouTube](https://www.youtube.com/watch?v=61wGzIv12Ds)
      # - [Installing NixOS with Hyprland! - by Josiah - Tech Prose](https://josiahalenbrown.substack.com/p/installing-nixos-with-hyprland)
      ({...}: {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
        };

        environment.systemPackages = with pkgs; [
          dunst
          libnotify
          networkmanagerapplet
          brightnessctl
          inotify-tools
          wirelesstools

          # widget/bar
          eww
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
          wev # like xev

          # color picker
          hyprpicker

          # plugin manager
          unstable.pyprland
          # plugins
          # unstable.hyprcursor
          unstable.hyprlock
          unstable.hypridle
          unstable.hyprshot

          papirus-icon-theme
          adwaita-qt
          gnome.adwaita-icon-theme

          (pkgs.writeShellScriptBin "start-hypr" ''
            export XDG_SESSION_TYPE=wayland

            ${pkgs.hyprland}/bin/Hyprland
          '')
        ];

        home-manager.users."${username}" = {config, ...}: {
          wayland.windowManager.hyprland = {
            enable = true;
            plugins = [
              (flakePackage inputs.hyprkool "hyprkool-plugin")
            ];
            extraConfig = ''
              source = ~/.config/hypr/hyprland_nonix.conf
            '';
          };
        };

        xdg.portal = {
          enable = true;
          wlr.enable = true;
          extraPortals = [pkgs.xdg-desktop-portal-gtk];
        };

        fonts.packages = with pkgs; [
          nerdfonts
          meslo-lgs-nf
        ];

        # - [use unstable mesa for hyprland-git / unstable hyprland](https://github.com/hyprwm/Hyprland/issues/5148#issuecomment-2002533086)
        # - [also on hyprland wiki](https://wiki.hyprland.org/0.38.0/Nix/Hyprland-on-NixOS/)
        hardware.opengl = {
          package = pkgs.unstable.mesa.drivers;
          package32 = pkgs.unstable.pkgsi686Linux.mesa.drivers;
        };
      })
    ];
  in {
    nixosConfigurations = {
      ga402xu = inputs.nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "ga402xu";
          inherit inputs pkgs system username;
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
