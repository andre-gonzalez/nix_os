{ config, pkgs, inputs, customPkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    ../../modules/nixos/hardware/intel.nix
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  networking.hostName = "samsung-expert";

  # Broadcom WiFi driver (required for Samsung Expert Book)
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  networking.wireless.enable = true; # use wpa_supplicant (or switch to iwd)

  # Mount points for internal drives
  fileSystems."/mnt/hd-interno" = {
    device = "/dev/disk/by-partuuid/72749a9f-5496-4700-ad5e-f4f2eaad8da5";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  fileSystems."/mnt/ntfs-hd-interno" = {
    device = "/dev/disk/by-partuuid/f41cf00e-dbf1-431f-a833-9f9e20ebed89";
    fsType = "ntfs3";
    options = [ "defaults" "nofail" ];
  };

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = false;
    default = "saved";
    timeout = 1;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    "audit=1"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.frank = import ../../modules/home;
    extraSpecialArgs = { inherit inputs customPkgs; };
  };

  system.stateVersion = "25.05";
}
