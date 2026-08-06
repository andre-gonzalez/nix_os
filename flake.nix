{
  description = "André Gonzalez – NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, agenix, disko, nixos-hardware, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customPkgs = import ./pkgs { inherit pkgs; lib = nixpkgs.lib; };
    in
    {
      nixosConfigurations = {
        workstation = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs customPkgs; };
          modules = [
            ./hosts/workstation/default.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
          ];
        };

        samsung-expert = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs customPkgs; };
          modules = [
            ./hosts/samsung-expert/default.nix
            # nixos-hardware.nixosModules.samsung-galaxy-book  # uncomment closest match
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
          ];
        };
      };

      packages.${system} = customPkgs;
    };
}
