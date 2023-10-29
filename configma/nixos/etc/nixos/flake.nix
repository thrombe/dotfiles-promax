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

    helix-git.url = "github:helix-editor/helix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-hardware,
    nix-index-database,
    helix-git,
    # home-manager,
  }: let
    system = "x86_64-linux";

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
          helix = helix-git.packages."${system}".helix;
          asusctl = super.unstable.asusctl;
        })
      ];
    };
  in {
    nixosConfigurations = {
      gl553ve = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "gl553ve";
          inherit pkgs system;
        };

        modules = [
          ./configuration.nix
          ./${specialArgs.hostname}/configuration.nix
          nix-index-database.nixosModules.nix-index
        ];
      };

      ga402xu = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          hostname = "ga402xu";
          inherit pkgs system;
        };

        modules = [
          ./configuration.nix
          ./${specialArgs.hostname}/configuration.nix
          nixos-hardware.nixosModules.asus-zephyrus-ga402
          nix-index-database.nixosModules.nix-index
        ];
      };
    };
  };
}
