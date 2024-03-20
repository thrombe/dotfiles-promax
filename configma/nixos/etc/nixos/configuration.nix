# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  hostname,
  username,
  ...
}: {
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
  ];
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
      firefox
      librewolf
      ungoogled-chromium
      zathura
      stremio
      # discord # TODO: make voice work
      qbittorrent

      # tools
      helix
      unstable.alacritty
      unstable.zellij
      unstable.zoxide
      unstable.yazi
      unstable.broot
      unstable.gitui
      unstable.delta
      unstable.distrobox
      starship
      ueberzugpp
      neovim
      fzf
      ripdrag
      kalker
      libqalculate
      sshfs
      neofetch
      unoconv
      (pkgs.writeScriptBin "convert-all-to-pdf" ''
        #!/usr/bin/env zsh
        mkdir -p unconverted
        for i in ./**.(doc|ppt|xls|docx|pptx|xlsx); do
          ${unoconv}/bin/unoconv -f pdf ./$i
          mv $i ./unconverted/$i
        done
      '')

      btop
      s-tui # fan rpm + other stuff
      nvtop # gpu stats
      # bottom # battery stat + other stuff
      # battop # only battery stat

      # - [Virt-manager - NixOS Wiki](https://nixos.wiki/wiki/Virt-manager)
      virtiofsd
      qemu

      # rice
      lightly-qt

      # system behavior
      # libsForQt5.bismuth
      xorg.xmodmap
      xdotool
      # wtype # 'xdotool type' for wayland
      xorg.xhost
      xclip
      wmctrl
      numlockx
      libnotify
      zsh-fzf-tab

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

      # nix
      nil
      alejandra # nix formatter
      nixos-option
      cached-nix-shell
      nix-tree
      nix-melt # flake.lock visualizer
      nix-alien

      # dev
      # rustup
      libclang
      git
      gcc
      (python3Full.withPackages (ps:
        with ps; [
          # TODO: try this with a nix derivation
          # for lbwopen
          pyperclip
          colorama
        ]))
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
}
