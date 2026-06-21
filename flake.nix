{
  description = "Cross-platform dotfiles managed by Nix and chezmoi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs:
    let
      user = "ryodocx";
      email = "email@ryodocx.net";
    in {
      # macOS (nix-darwin + Home Manager)
      darwinConfigurations = {
        "macbook" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./hosts/macbook/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./modules/home/default.nix;
              home-manager.extraSpecialArgs = {
                inherit user email;
                isDarwin = true;
                isWSL = false;
              };
            }
          ];
          specialArgs = { inherit inputs; };
        };
      };

      # Linux / WSL (Home Manager standalone)
      homeConfigurations = {
        "wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./hosts/wsl/default.nix ];
          extraSpecialArgs = {
            inherit user email;
            isDarwin = false;
            isWSL = true;
          };
        };
        "linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./hosts/linux/default.nix ];
          extraSpecialArgs = {
            inherit user email;
            isDarwin = false;
            isWSL = false;
          };
        };
      };
    };
}
