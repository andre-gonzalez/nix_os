{ config, pkgs, inputs, customPkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    # ../../modules/nixos/hardware/nvidia.nix   # uncomment if applicable
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/services/snapper.nix
    ../../modules/nixos/services/preload.nix
    ../../modules/nixos/virtualization/libvirt.nix
  ];

  networking.hostName = "workstation";

  # GRUB with btrfs snapshot boot support
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = false;
    default = "saved";
    timeout = 1;
    gfxmodeEfi = "auto";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for AppArmor + audit
  boot.kernelParams = [
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    "audit=1"
  ];

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.frank = import ../../modules/home;
    extraSpecialArgs = { inherit inputs customPkgs; };
  };

  system.stateVersion = "25.05"; # set once, do not update
}
