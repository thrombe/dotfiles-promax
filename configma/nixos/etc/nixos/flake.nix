{
  description = "yaaaaaaaaaaaaaaaaaaaaa";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager = {
    #   url = "github:nix-community/home-manager/release-23.05";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix-git = {
      url = "github:helix-editor/helix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    configma = {
      url = "github:thrombe/configma";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };
    nix-update-input = {
      url = "github:vimjoyer/nix-update-input";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-hardware,
    nix-index-database,
    helix-git,
    configma,
    nix-update-input,
    # home-manager,
  }: let
    system = "x86_64-linux";
    username = "issac";

    # helpers
    flakeDefaultPackage = flake: flake.packages."${system}".default;

    overlay-unstable = final: prev: {
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        overlay-unstable
        (self: super: {
          helix = flakeDefaultPackage helix-git;
          asusctl = super.unstable.asusctl;
        })
      ];
    };

    commonModules = [
      {_module.args = inputs;}
      ./configuration.nix
      nix-index-database.nixosModules.nix-index

      # - [install a flake package](https://discourse.nixos.org/t/how-to-install-a-python-flake-package-via-configuration-nix/26970/2)
      ({...}: {
        users.users."${username}".packages = map flakeDefaultPackage [
          configma
          nix-update-input # update-input
        ];
      })
    ];
  in {
    nixosConfigurations = {
      gl553ve = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "gl553ve";
          inherit pkgs system username;
        };

        modules =
          commonModules
          ++ [
            ./${specialArgs.hostname}/configuration.nix
          ];
      };

      ga402xu = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "ga402xu";
          inherit pkgs system username;
        };

        modules =
          commonModules
          ++ [
            ./${specialArgs.hostname}/configuration.nix
            nixos-hardware.nixosModules.asus-zephyrus-ga402
          ];
      };
    };
  };
}
