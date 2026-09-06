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
        # ThinkPad T14 Gen 6 (AMD). Replaces the old `workstation` host.
        #
        # Deliberately NOT nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen5:
        # there is no gen6 module upstream, and gen5 hardcodes acpi.ec_no_wakeup=1
        # for a Gen 5 EC bug. Once imported, a single kernel param cannot be
        # removed without mkForce-ing the whole list. Compose the common modules
        # instead.
        t14 = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs customPkgs; };
          modules = [
            ./hosts/t14/default.nix
            nixos-hardware.nixosModules.lenovo-thinkpad       # trackpoint + emulateWheel; pulls common/pc/laptop
            nixos-hardware.nixosModules.common-cpu-amd-pstate # amd_pstate=active
            nixos-hardware.nixosModules.common-gpu-amd        # modesetting, graphics.enable32Bit, amdgpu.initrd
            nixos-hardware.nixosModules.common-pc-ssd         # fstrim
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            disko.nixosModules.disko
          ];
        };

        # Same host, reshaped for an unattended nixos-anywhere install onto a
        # test machine: LUKS passphrase from a file, no initrd keyfile, no
        # agenix, its own hardware scan. See hosts/t14/remote-install.nix.
        t14-remote = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs customPkgs; };
          modules = [
            ./hosts/t14/remote-install.nix
            # Target-specific (see the header of remote-install.nix): Intel CPU
            # + iGPU, NVIDIA dGPU blacklisted and unbound. common-pc-laptop
            # replaces lenovo-thinkpad, which pulled it in transitively.
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-nvidia-disable
            nixos-hardware.nixosModules.common-pc-ssd
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
