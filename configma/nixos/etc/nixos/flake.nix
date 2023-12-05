{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";

    # home-manager = {
    #   url = "github:nix-community/home-manager/release-23.05";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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

  outputs = inputs @ {nixpkgs, ...}: let
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

    commonModules = [
      # {_module.args = inputs;}
      ./configuration.nix
      inputs.nix-index-database.nixosModules.nix-index

      # - [install a flake package](https://discourse.nixos.org/t/how-to-install-a-python-flake-package-via-configuration-nix/26970/2)
      ({...}: {
        users.users."${username}".packages =
          (map flakeDefaultPackage (with inputs; [
            configma
            yankpass
            nix-update-input # update-input
          ]))
          ++ (map getScript [
            "wait-until"
          ]);
      })
    ];
  in {
    nixosConfigurations = {
      ga402xu = nixpkgs.lib.nixosSystem rec {
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
